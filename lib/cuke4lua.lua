libdir = arg[1]
local socket = require "socket"
package.path = libdir .. "\\?.lua;" .. package.path
require "json"

host = "127.0.0.1"
port = arg[3] or 3901

file = arg[2]
-- TODO: load file if set
--require file

-- TODO: Put logfile in standard location
--require "logging.console"
--local log = logging.console("%date %level %message\n")
require "logging.file"
local log = logging.file("test%s.log", "%Y-%m-%d", "%date %level %message\n")

log:info(string.format("Starting cuke4lua server on host %s port %s", host, port))

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()

--local skip = conn:receive()

local obj
input = function(data)
  obj = json.decode(data)
end

output = function(o)
  conn:send( json.encode(o) .. "\n" )
end

success = function(x)
  local t = {"success"}
  if x then table.insert(t, x) end
  output(t)
end

fail = function(s)
  log:warn(s)
  output({"fail",{message=s,exception="Cuke4LuaFailure"}})
end

local e
repeat
  local data,e = conn:receive()

  if data then
    if pcall(function () input(data) end) then
      log:info("JSON message received: " .. data)
      local op = obj[0]
      if (op == "begin_scenario" ) then
        log:info("Beginning scenario")
        success()
      elseif (op == "step_matches") then
        log:info("Finding step matches")
        success({})
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
