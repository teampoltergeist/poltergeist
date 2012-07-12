# This is injected into each page that is loaded

class PoltergeistAgent
  constructor: ->
    @elements = []
    @nodes    = {}
    @windows  = []
    this.pushWindow(window)

  externalCall: (name, args) ->
    try
      { value: this[name].apply(this, args) }
    catch error
      { error: { message: error.toString(), stack: error.stack } }

  @stringify: (object) ->
    JSON.stringify object, (key, value) ->
      if Array.isArray(this[key])
        return this[key]
      else
        return value

  pushWindow: (new_window) ->
    @windows.push(new_window)

    @window   = new_window
    @document = @window.document

    null

  popWindow: ->
    @windows.pop()

    @window   = @windows[@windows.length - 1]
    @document = @window.document

    null

  pushFrame: (id) ->
    this.pushWindow @document.getElementById(id).contentWindow

  popFrame: ->
    this.popWindow()

  currentUrl: ->
    window.location.toString()

  find: (selector, within = @document) ->
    results = @document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
    ids     = []

    for i in [0...results.snapshotLength]
      ids.push(this.register(results.snapshotItem(i)))

    ids

  register: (element) ->
    @elements.push(element)
    @elements.length - 1

  documentSize: ->
    height: @document.documentElement.scrollHeight,
    width:  @document.documentElement.scrollWidth

  get: (id) ->
    @nodes[id] or= new PoltergeistAgent.Node(this, @elements[id])

  nodeCall: (id, name, args) ->
    node = this.get(id)
    throw new PoltergeistAgent.ObsoleteNode if node.isObsolete()
    node[name].apply(node, args)

class PoltergeistAgent.ObsoleteNode
  toString: -> "PoltergeistAgent.ObsoleteNode"

class PoltergeistAgent.Node
  @EVENTS = {
    FOCUS: ['blur', 'focus', 'focusin', 'focusout'],
    MOUSE: ['click', 'dblclick', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove',
            'mouseover', 'mouseout', 'mouseup']
  }

  constructor: (@agent, @element) ->

  parentId: ->
    @agent.register(@element.parentNode)

  find: (selector) ->
    @agent.find(selector, @element)

  isObsolete: ->
    obsolete = (element) =>
      if element.parentNode?
        if element.parentNode == @agent.document
          false
        else
          obsolete element.parentNode
      else
        true
    obsolete @element

  changed: ->
    event = document.createEvent('HTMLEvents')
    event.initEvent('change', true, false)
    @element.dispatchEvent(event)

  input: ->
    event = document.createEvent('HTMLEvents')
    event.initEvent('input', true, false)
    @element.dispatchEvent(event)

  keyupdowned: (eventName, keyCode) ->
    event = document.createEvent('UIEvents')
    event.initEvent(eventName, true, true)
    event.keyCode  = keyCode
    event.which    = keyCode
    event.charCode = 0
    @element.dispatchEvent(event)

  keypressed: (altKey, ctrlKey, shiftKey, metaKey, keyCode, charCode) ->
    event = document.createEvent('UIEvents')
    event.initEvent('keypress', true, true)
    event.window   = @agent.window
    event.altKey   = altKey
    event.ctrlKey  = ctrlKey
    event.shiftKey = shiftKey
    event.metaKey  = metaKey
    event.keyCode  = keyCode
    event.charCode = charCode
    event.which    = keyCode
    @element.dispatchEvent(event)

  insideBody: ->
    @element == @agent.document.body ||
    @agent.document.evaluate('ancestor::body', @element, null, XPathResult.BOOLEAN_TYPE, null).booleanValue

  text: ->
    return '' unless this.isVisible()

    if this.insideBody()
      el = @element
    else
      el = @agent.document.body

    results = @agent.document.evaluate('.//text()[not(ancestor::script)]', el, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
    text    = ''

    for i in [0...results.snapshotLength]
      node = results.snapshotItem(i)
      text += node.textContent if this.isVisible(node.parentNode)
    text

  getAttribute: (name) ->
    if name == 'checked' || name == 'selected'
      @element[name]
    else
      @element.getAttribute(name)

  scrollIntoView: ->
    @element.scrollIntoViewIfNeeded()

  value: ->
    if @element.tagName == 'SELECT' && @element.multiple
      option.value for option in @element.children when option.selected
    else
      @element.value

  set: (value) ->
    if (@element.maxLength >= 0)
      value = value.substr(0, @element.maxLength)

    @element.value = ''
    this.trigger('focus')

    for char in value
      @element.value += char

      keyCode = this.characterToKeyCode(char)
      this.keyupdowned('keydown', keyCode)
      this.keypressed(false, false, false, false, char.charCodeAt(0), char.charCodeAt(0))
      this.keyupdowned('keyup', keyCode)

    this.changed()
    this.input()
    this.trigger('blur')

  isMultiple: ->
    @element.multiple

  setAttribute: (name, value) ->
    @element.setAttribute(name, value)

  removeAttribute: (name) ->
    @element.removeAttribute(name)

  select: (value) ->
    if value == false && !@element.parentNode.multiple
      false
    else
      @element.selected = value
      this.changed()
      true

  tagName: ->
    @element.tagName

  isVisible: (element) ->
    element = @element unless element

    if @agent.window.getComputedStyle(element).display == 'none'
      false
    else if element.parentElement
      this.isVisible element.parentElement
    else
      true

  position: ->
    rect = @element.getClientRects()[0]

    {
      top:    rect.top,
      right:  rect.right,
      left:   rect.left,
      bottom: rect.bottom,
      width:  rect.width,
      height: rect.height
    }

  trigger: (name) ->
    if Node.EVENTS.MOUSE.indexOf(name) != -1
      event = document.createEvent('MouseEvent')
      event.initMouseEvent(
        name, true, true, @agent.window, 0, 0, 0, 0, 0,
        false, false, false, false, 0, null
      )
    else if Node.EVENTS.FOCUS.indexOf(name) != -1
      event = document.createEvent('HTMLEvents')
      event.initEvent(name, true, true)
    else
      throw "Unknown event"

    @element.dispatchEvent(event)

  clickTest: (x, y) ->
    el = origEl = document.elementFromPoint(x, y)

    while el
      if el == @element
        return { status: 'success' }
      else
        el = el.parentNode

    { status: 'failure', selector: origEl && this.getSelector(origEl) }

  getSelector: (el) ->
    selector = if el.tagName != 'HTML' then this.getSelector(el.parentNode) + ' ' else ''
    selector += el.tagName.toLowerCase()
    selector += "##{el.id}" if el.id
    for className in el.classList
      selector += ".#{className}"
    selector

  characterToKeyCode: (character) ->
    code = character.toUpperCase().charCodeAt(0)
    specialKeys =
      96: 192  #`
      45: 189  #-
      61: 187  #=
      91: 219  #[
      93: 221  #]
      92: 220  #\
      59: 186  #;
      39: 222  #'
      44: 188  #,
      46: 190  #.
      47: 191  #/
      127: 46  #delete
      126: 192 #~
      33: 49   #!
      64: 50   #@
      35: 51   ##
      36: 52   #$
      37: 53   #%
      94: 54   #^
      38: 55   #&
      42: 56   #*
      40: 57   #(
      41: 48   #)
      95: 189  #_
      43: 187  #+
      123: 219 #{
      125: 221 #}
      124: 220 #|
      58: 186  #:
      34: 222  #"
      60: 188  #<
      62: 190  #>
      63: 191 #?

    specialKeys[code] || code

  isDOMEqual: (other_id) ->
    @element == @agent.get(other_id).element

window.__poltergeist = new PoltergeistAgent

document.addEventListener(
  'DOMContentLoaded',
  -> console.log('__DOMContentLoaded')
)

window.confirm = (message) -> true
window.prompt  = (message, _default) -> _default or null
