libdir = arg[1]
package.path = libdir .. "\\?.lua;" .. package.path
local socket = require "socket"
local regex = require('rex_pcre')
local json = require "json"

host = "127.0.0.1"
port = arg[3] or 3901

file = arg[2]
if file then 
  cuke = {}
  dofile(file)
end

-- TODO: Put logfile in standard location
--require "logging.console"
--local log = logging.console("%date %level %message\n")
require "logging.file"
local log = logging.file("test%s.log", "%Y-%m-%d", "%date %level %message\n")

log:info(string.format("Starting cuke4lua server on host %s port %s with file %s", host, port, file or "NONE"))

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()


local obj
input = function(data)
  obj = json.decode(data)
end

output = function(o)
  local s = json.encode(o)
  log:info("Sending: " .. s)
  conn:send(s .. "\n")
end

success = function(x)
  local t = {"success"}
  if x then table.insert(t, x) end
  output(t)
end

fail = function(s)
  output({"fail",{message=s,exception="Cuke4LuaFailure"}})
end

local e
repeat
  local data,e = conn:receive()

  if data then
    if pcall(function () input(data) end) then
      log:info("JSON message received: " .. data)
      local op = obj[1]
      if (op == "begin_scenario" ) then
        log:info("Beginning scenario")
        for k,v in pairs(cuke) do
          if cuke.Before then cuke.Step() end
        end
        success()
      elseif (op == "end_scenario" ) then
        log:info("Ending scenario")
        for k,v in pairs(cuke) do
          if cuke.After then cuke.Step() end
        end
        success()
      elseif (op == "step_matches") then
        log:info("Finding step matches")
        local matches = {}
        local nameToMatch = obj[2].name_to_match
        if cuke then
          for k,v in pairs(cuke) do
            local stepRegex = v.Given or v.When or v.Then
            if stepRegex and regex.match(nameToMatch, stepRegex) then
              -- TODO: set pending in json if v.Pending
              table.insert(matches,{id=k,args={}})
            end
          end
        end
        success(matches)
      elseif (op == "invoke") then
        if cuke then
          local opts = obj[2]
          local id = opts.id
          local args = opts.args
          cuke[tostring(id)].Step(unpack(args))
          success()
        else
          fail("No steps defined")
        end
      else
        fail("Don't know how to " .. op)
      end
    else
      fail("JSON parse failure for: " .. data)
    end
  end
until data == nil

if e then
  log:warn("Connection error: " .. e)
end
log:info("Shutting down server")
