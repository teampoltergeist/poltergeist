class Poltergeist
  constructor: (port, width, height, host) ->
    @browser    = new Poltergeist.Browser(width, height)
    @connection = new Poltergeist.Connection(this, port, host)

    phantom.onError = (message, stack) => @onError(message, stack)

  runCommand: (command) ->
    new Poltergeist.Cmd(this, command.id, command.name, command.args).run(@browser)

  sendResponse: (command_id, response) ->
    this.send(command_id: command_id, response: response)

  sendError: (command_id, error) ->
    this.send(
      command_id: command_id,
      error:
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
    )

  send: (data) ->
    @connection.send(data)
    return true

# This is necessary because the remote debugger will wrap the
# script in a function, causing the Poltergeist variable to
# become local.
window.Poltergeist = Poltergeist

class Poltergeist.Error

class Poltergeist.ObsoleteNode extends Poltergeist.Error
  name: "Poltergeist.ObsoleteNode"
  args: -> []
  toString: -> this.name

class Poltergeist.InvalidSelector extends Poltergeist.Error
  constructor: (@method, @selector) ->
  name: "Poltergeist.InvalidSelector"
  args: -> [@method, @selector]

class Poltergeist.FrameNotFound extends Poltergeist.Error
  constructor: (@frameName) ->
  name: "Poltergeist.FrameNotFound"
  args: -> [@frameName]

class Poltergeist.MouseEventFailed extends Poltergeist.Error
  constructor: (@eventName, @selector, @position) ->
  name: "Poltergeist.MouseEventFailed"
  args: -> [@eventName, @selector, @position]

class Poltergeist.KeyError extends Poltergeist.Error
  constructor: (@message) ->
  name: "Poltergeist.KeyError"
  args: -> [@message]

class Poltergeist.JavascriptError extends Poltergeist.Error
  constructor: (@errors) ->
  name: "Poltergeist.JavascriptError"
  args: -> [@errors]

class Poltergeist.BrowserError extends Poltergeist.Error
  constructor: (@message, @stack) ->
  name: "Poltergeist.BrowserError"
  args: -> [@message, @stack]

class Poltergeist.StatusFailError extends Poltergeist.Error
  constructor: (@url, @details) ->
  name: "Poltergeist.StatusFailError"
  args: -> [@url, @details]

class Poltergeist.NoSuchWindowError extends Poltergeist.Error
  name: "Poltergeist.NoSuchWindowError"
  args: -> []

class Poltergeist.ScriptTimeoutError extends Poltergeist.Error
  name: "Poltergeist.ScriptTimeoutError"
  args: -> []

class Poltergeist.UnsupportedFeature extends Poltergeist.Error
  constructor: (@message) ->
  name: "Poltergeist.UnsupportedFeature"
  args: -> [@message, phantom.version]

# We're using phantom.libraryPath so that any stack traces
# report the full path.
phantom.injectJs("#{phantom.libraryPath}/web_page.js")
phantom.injectJs("#{phantom.libraryPath}/node.js")
phantom.injectJs("#{phantom.libraryPath}/connection.js")
phantom.injectJs("#{phantom.libraryPath}/cmd.js")
phantom.injectJs("#{phantom.libraryPath}/browser.js")

system = require 'system'
new Poltergeist(system.args[1], system.args[2], system.args[3], system.args[4])
