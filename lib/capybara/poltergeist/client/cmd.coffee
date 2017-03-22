class Poltergeist.Cmd
  constructor: (@owner, @id, @name, @args)->
    @_response_sent = false
  sendResponse: (response) ->
    if !@_response_sent
      errors = @browser.currentPage.errors
      @browser.currentPage.clearErrors()

      if errors.length > 0 && @browser.js_errors
        @sendError(new Poltergeist.JavascriptError(errors))
      else
        @owner.sendResponse(@id, response)
        @_response_sent = true

  sendError: (errors) ->
    if !@_response_sent
      @owner.sendError(@id, errors)
      @_response_sent = true

  run: (@browser) ->
    try
      @browser.runCommand(this)
    catch error
      if error instanceof Poltergeist.Error
        @sendError(error)
      else
        @sendError(new Poltergeist.BrowserError(error.toString(), error.stack))

