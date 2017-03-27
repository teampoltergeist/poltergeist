class Poltergeist.Connection
  constructor: (@owner, @port, @host = "127.0.0.1") ->
    @socket = new WebSocket "ws://#{@host}:#{@port}/"
    @socket.onmessage = this.commandReceived
    @socket.onclose = -> phantom.exit()

  commandReceived: (message) =>
    @owner.runCommand(JSON.parse(message.data))

  send: (message) ->
    @socket.send(JSON.stringify(message))
