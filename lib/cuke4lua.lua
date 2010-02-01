local socket = require "socket"
require "json"

host = "127.0.0.1"
port = arg[2] or 3901

file = arg[1]
-- TODO: load file if set
--require file

-- TODO: Put logfile in standard location
require "logging.console"
local log = logging.console("%date %level %message\n")
--require "logging.file"
--local log = logging.file("test%s.log", "%Y-%m-%d", "%date %level %message\n")

log:info(string.format("Starting cuke4lua server on host %s port %s", host, port))

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()

local skip = conn:receive()

input = function(data)
  local o = json.decode(data)
end

local e
repeat
  local data,e = conn:receive()

  if data then
    if pcall(function () input(data) end) then
      log:info("JSON message received: " .. data)
    else
      log:warn("JSON parse error for: " .. data)
    end
  end
until data == nil

if e then
  log:warn("Connection error: " .. e)
end
log:info("Shutting down server")
