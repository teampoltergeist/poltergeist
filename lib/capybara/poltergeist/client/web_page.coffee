class Poltergeist.WebPage
  @CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized',
                'onLoadStarted', 'onResourceRequested', 'onResourceReceived']
  @DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render']
  @COMMANDS  = ['currentUrl', 'find', 'nodeCall', 'pushFrame', 'popFrame', 'documentSize']

  constructor: ->
    @native  = require('webpage').create()
    @nodes   = {}
    @_source = ""

    this.setViewportSize(width: 1024, height: 768)

    for callback in WebPage.CALLBACKS
      this.bindCallback(callback)

    this.injectAgent()

  for command in @COMMANDS
    do (command) =>
      this.prototype[command] =
        (arguments...) -> this.runCommand(command, arguments)

  for delegate in @DELEGATES
    do (delegate) =>
      this.prototype[delegate] =
        -> @native[delegate].apply(@native, arguments)

  onInitializedNative: ->
    @_source = null
    this.injectAgent()
    this.setScrollPosition({ left: 0, top: 0 })

  injectAgent: ->
    if this.evaluate(-> typeof __poltergeist) == "undefined"
      @native.injectJs('agent.js')

  onConsoleMessageNative: (message) ->
    if message == '__DOMContentLoaded'
      @_source = @native.content
      false

  onLoadFinishedNative: ->
    @_source or= @native.content

  onConsoleMessage: (message) ->
    console.log(message)

  content: ->
    @native.content

  source: ->
    @_source

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
    changed    = false

    if dimensions.right > document.width
      dimensions.left -= dimensions.right - document.width
      dimensions.right = document.width
      changed = true

    if dimensions.bottom > document.height
      dimensions.top -= dimensions.bottom - document.height
      dimensions.bottom = document.height
      changed = true

    if changed
      this.setScrollPosition(left: dimensions.left, top: dimensions.top)

    dimensions

  get: (id) ->
    @nodes[id] or= new Poltergeist.Node(this, id)

  evaluate: (fn, args...) ->
    @native.evaluate("function() { return #{this.stringifyCall(fn, args)} }")

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

  runCommand: (name, arguments) ->
    this.evaluate(
      (name, arguments) -> __poltergeist[name].apply(__poltergeist, arguments),
      name, arguments
    )
