# This is injected into each page that is loaded

class PoltergeistAgent
  constructor: ->
    @elements = []
    @nodes    = {}
    @windows  = []
    this.pushWindow(window)

  externalCall: (name, arguments) ->
    try
      { value: this[name].apply(this, arguments) }
    catch error
      { error: error.toString() }

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

  find: (selector, id) ->
    context = if id? then @elements[id] else @document
    results = @document.evaluate(selector, context, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
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

  nodeCall: (id, name, arguments) ->
    node = this.get(id)
    throw new PoltergeistAgent.ObsoleteNode if node.isObsolete()
    node[name].apply(node, arguments)

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
    event.initEvent("change", true, false)
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

  value: ->
    if @element.tagName == 'SELECT' && @element.multiple
      option.value for option in @element.children when option.selected
    else
      @element.value

  set: (value) ->
    if (@element.maxLength >= 0)
      value = value.substr(0, @element.maxLength)

    @element.value = value
    this.changed()

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

window.__poltergeist = new PoltergeistAgent

document.addEventListener(
  'DOMContentLoaded',
  -> console.log('__DOMContentLoaded')
)

window.confirm = (message) -> true
window.prompt  = (message, _default) -> _default or null
