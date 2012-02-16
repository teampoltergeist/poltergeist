class Poltergeist
  constructor: (port) ->
    @browser    = new Poltergeist.Browser(this)
    @connection = new Poltergeist.Connection(this, port)

  runCommand: (command) ->
    try
      @browser[command.name].apply(@browser, command.args)
    catch error
      this.sendError(error.toString())

  sendResponse: (response) ->
    @connection.send({ response: response })

  sendError: (message) ->
    @connection.send({ error: message })

class Poltergeist.ObsoleteNode
  toString: -> "Poltergeist.ObsoleteNode"

phantom.injectJs('web_page.js')
phantom.injectJs('node.js')
phantom.injectJs('connection.js')
phantom.injectJs('browser.js')

new Poltergeist(phantom.args[0])
