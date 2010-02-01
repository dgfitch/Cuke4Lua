local socket = require "socket"

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

log:info("Starting cuke4lua server on host %s port %s", host, port)

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()
repeat
  data, e = conn:receive()
  log:info(data)
until not e
log:warn(e)

log:info("Shutting down server")
