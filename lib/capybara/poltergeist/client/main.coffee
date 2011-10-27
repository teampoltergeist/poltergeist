if phantom.version.major < 1 || phantom.version.minor < 3
  console.log "Poltergeist requires a PhantomJS version of at least 1.3"
  phantom.exit(1)

class Poltergeist
  constructor: (port) ->
    @browser    = new Poltergeist.Browser(this)
    @connection = new Poltergeist.Connection(this, port)

  runCommand: (command) ->
    try
      @browser[command.name].apply(@browser, command.args)
    catch error
      @connection.send({ error: error.toString() })

  sendResponse: (response) ->
    @connection.send({ response: response })

class Poltergeist.ObsoleteNode
  toString: -> "Poltergeist.ObsoleteNode"

phantom.injectJs('web_page.js')
phantom.injectJs('node.js')
phantom.injectJs('connection.js')
phantom.injectJs('browser.js')

new Poltergeist(phantom.args[0])
