class Poltergeist.WebPage
  @CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized',
                'onLoadStarted', 'onResourceRequested', 'onResourceReceived',
                'onError']

  @DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render']

  @COMMANDS  = ['currentUrl', 'find', 'nodeCall', 'pushFrame', 'popFrame', 'documentSize']

  constructor: ->
    @native  = require('webpage').create()
    @_source = ""
    @_errors = []

    this.setViewportSize(width: 1024, height: 768)

    for callback in WebPage.CALLBACKS
      this.bindCallback(callback)

    this.injectAgent()

  for command in @COMMANDS
    do (command) =>
      this.prototype[command] =
        (args...) -> this.runCommand(command, args)

  for delegate in @DELEGATES
    do (delegate) =>
      this.prototype[delegate] =
        -> @native[delegate].apply(@native, arguments)

  onInitializedNative: ->
    @_source = null
    this.injectAgent()
    this.setScrollPosition(left: 0, top: 0)

  injectAgent: ->
    if @native.evaluate(-> typeof __poltergeist) == "undefined"
      @native.injectJs("#{phantom.libraryPath}/agent.js")
      @nodes = {}

  onConsoleMessageNative: (message) ->
    if message == '__DOMContentLoaded'
      @_source = @native.content
      false

  onLoadFinishedNative: ->
    @_source or= @native.content

  onConsoleMessage: (message, line, file) ->
    # The conditional works around a PhantomJS bug where an error can
    # get wrongly reported to be onError and onConsoleMessage:
    #
    # http://code.google.com/p/phantomjs/issues/detail?id=166#c18
    unless @_errors.length && @_errors[@_errors.length - 1].message == message
      console.log(message)

  onErrorNative: (message, stack) ->
    @_errors.push(message: message, stack: stack)

  content: ->
    @native.content

  source: ->
    @_source

  errors: ->
    @_errors

  clearErrors: ->
    @_errors = []

  viewportSize: ->
    @native.viewportSize

  setViewportSize: (size) ->
    @native.viewportSize = size

  scrollPosition: ->
    @native.scrollPosition

  setScrollPosition: (pos) ->
    @native.scrollPosition = pos

  clipRect: ->
    @native.clipRect

  setClipRect: (rect) ->
    @native.clipRect = rect

  dimensions: ->
    scroll   = this.scrollPosition()
    viewport = this.viewportSize()

    top:    scroll.top,  bottom: scroll.top  + viewport.height,
    left:   scroll.left, right:  scroll.left + viewport.width,
    viewport: viewport
    document: this.documentSize()

  # A work around for http://code.google.com/p/phantomjs/issues/detail?id=277
  validatedDimensions: ->
    dimensions = this.dimensions()
    document   = dimensions.document

    orig_left = dimensions.left
    orig_top  = dimensions.top

    if dimensions.right > document.width
      dimensions.left  = Math.max(0, dimensions.left - (dimensions.right - document.width))
      dimensions.right = document.width

    if dimensions.bottom > document.height
      dimensions.top    = Math.max(0, dimensions.top - (dimensions.bottom - document.height))
      dimensions.bottom = document.height

    this.setScrollPosition(left: dimensions.left, top: dimensions.top)

    dimensions

  get: (id) ->
    @nodes[id] or= new Poltergeist.Node(this, id)

  evaluate: (fn, args...) ->
    JSON.parse @native.evaluate("function() { return PoltergeistAgent.stringify(#{this.stringifyCall(fn, args)}) }")

  execute: (fn, args...) ->
    @native.evaluate("function() { #{this.stringifyCall(fn, args)} }")

  stringifyCall: (fn, args) ->
    if args.length == 0
      "(#{fn.toString()})()"
    else
      # The JSON.stringify happens twice because the second time we are essentially
      # escaping the string.
      "(#{fn.toString()}).apply(this, JSON.parse(#{JSON.stringify(JSON.stringify(args))}))"

  # For some reason phantomjs seems to have trouble with doing 'fat arrow' binding here,
  # hence the 'that' closure.
  bindCallback: (name) ->
    that = this
    @native[name] = ->
      if that[name + 'Native']? # For internal callbacks
        result = that[name + 'Native'].apply(that, arguments)

      if result != false && that[name]? # For externally set callbacks
        that[name].apply(that, arguments)

  # Any error raised here or inside the evaluate will get reported to
  # phantom.onError. If result is null, that means there was an error
  # inside the agent.
  runCommand: (name, args) ->
    result = this.evaluate(
      (name, args) -> __poltergeist.externalCall(name, args),
      name, args
    )

    result && result.value
