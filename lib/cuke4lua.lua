local socket = require "socket"

host = "127.0.0.1"
port = arg[1] or 4445


-- TODO: Put logfile in standard location
require "logging.console"
local log = logging.console("%date %level %message\n")

log:info("Starting cuke4lua server on host %s port %s", host, port)

server = assert(socket.bind(host, port))
server:settimeout(60)
conn = server:accept()
repeat
  data, e = conn:receive()
until not e
log:warn(e)

log:info("Shutting down server)
