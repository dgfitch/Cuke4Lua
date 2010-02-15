libdir = arg[1]
package.path = libdir .. "\\?.lua;" .. package.path
local socket = require "socket"
local regex = require('rex_pcre')
local json = require "json"

host = "127.0.0.1"
port = arg[3] or 3901

cuke = {}
file = arg[2]
if file then dofile(file) end

-- TODO: Put logfile in standard location
--require "logging.console"
--local log = logging.console("%date %level %message\n")
require "logging.file"
local log = logging.file("test%s.log", "%Y-%m-%d", "%date %level %message\n")

log:info(string.format("Starting cuke4lua server on host %s port %s with file %s", host, port, file or "NONE"))

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()


-- This needs to be called via pcall in case it blows up, and I'm not sure how 
-- to wrap a return value otherwise, so I'm stashing it...
local obj
input = function(data)
  obj = json.decode(data)
end

output = function(o)
  local s = json.encode(o)
  log:info("Sending: " .. s)
  conn:send(s .. "\n")
end

success = function(args)
  local t = {"success"}
  if args then table.insert(t, args) end
  output(t)
end

fail = function(s)
  output({"fail",{message=s,exception="Cuke4LuaFailure"}})
end

responses = {
  begin_scenario = function()
    log:info("Beginning scenario")
    if cuke then
      for k,v in pairs(cuke) do
        if type(v) == "table" and v.Before then v.Step() end
      end
    end
    success()
  end,

  end_scenario = function()
    log:info("Ending scenario")
    if cuke then
      for k,v in pairs(cuke) do
        if type(v) == "table" and v.After then v.Step() end
      end
    end
    success()
  end,

  step_matches = function(opts)
    log:info("Finding step matches")
    local matches = {}
    local nameToMatch = opts.name_to_match
    if cuke then
      for k,v in pairs(cuke) do
        if type(v) == "table" then
          local stepRegex = v.Given or v.When or v.Then
          if stepRegex then
            if regex.match(nameToMatch, stepRegex) then
              local args = {}
              regex.gsub(nameToMatch, stepRegex,
                function(...)
                  for i,v in ipairs(args) do
                    -- TODO: Not sure how to get capture position with lrexlib
                    table.insert(args,{val=v,pos=0})
                  end
                end)
              local value = {id=k,args=args}
              table.insert(matches,value)
            end
          end
        end
      end
    end
    success(matches)
  end,

  invoke = function(opts)
    if cuke then
      local args = opts.args
      local f = cuke[tostring(opts.id)]
      if f.Pending then
        local result = "TODO"
        if type(f.Pending) == "string" then
          result = f.Pending
        end
        output({"pending",result})
      else
        f.Step(unpack(args))
        success()
      end
    else
      fail("No steps defined")
    end
  end,

  snippet_text = function(opts)
    local keyword = opts.step_keyword
    local step_name = opts.step_name
    local arg_class = opts.multiline_arg_class
    local function case_helper(first, rest)
      return first:upper()..rest:lower()
    end
    local fixed_name = step_name:gsub("(%a)([%w_']*)", case_helper):gsub("[^a-zA-Z]", "")
    local args
    if (not arg_class or arg_class == "") then
      args = ""
    elseif (arg_class == "Cucumber::Ast::Table") then
      args = "table"
    elseif (arg_class == "Cucumber::Ast::PyString") then
      args = "s"
    else
      args = arg_class
    end
    local snippet = string.format("cuke.%s = {\n  Pending = true,\n  Given = \"^%s$\",\n  Step = function(%s)\n  end\n}\n", fixed_name, step_name, args)
    success(snippet)
  end
}


local e
repeat
  local data,e = conn:receive()

  if data then
    if pcall(function () input(data) end) then
      log:info("JSON message received: " .. data)
      local op = obj[1]
      local f = responses[op]
      if f then
        f(obj[2])
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
