class Poltergeist
  constructor: (port) ->
    @browser    = new Poltergeist.Browser(this)
    @connection = new Poltergeist.Connection(this, port)

  runCommand: (command) ->
    try
      @browser[command.name].apply(@browser, command.args)
    catch error
      this.sendError(error)

  sendResponse: (response) ->
    @connection.send(response: response)

  sendError: (error) ->
    @connection.send(
      error:
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
    )

# This is necessary because the remote debugger will wrap the
# script in a function, causing the Poltergeist variable to
# become local.
window.Poltergeist = Poltergeist

class Poltergeist.ObsoleteNode
  name: "Poltergeist.ObsoleteNode"
  args: -> []

class Poltergeist.ClickFailed
  constructor: (@selector, @position) ->
  name: "Poltergeist.ClickFailed"
  args: -> [@selector, @position]

class Poltergeist.JavascriptError
  constructor: (@errors) ->
  name: "Poltergeist.JavascriptError"
  args: -> [@errors]

phantom.injectJs('web_page.js')
phantom.injectJs('node.js')
phantom.injectJs('connection.js')
phantom.injectJs('browser.js')

new Poltergeist(phantom.args[0])
