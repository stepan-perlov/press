QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")
Region = require("../../region/region.coffee")
Text = require("../text.coffee")
Static = require("../../static/static.coffee")
HTMLString = require("../../../html_string/html_string.coffee")
HTMLSelection = require("../../../html_selection/html_selection.coffee")

QUnit.module "press.dom.Text",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.getElementById("qunit-fixture"))
        @text = new Text(@root, "p", {}, "Lorem <b>ipsum</b> it dolor")

QUnit.test "Text.type()", (assert)->
    assert.equal @text.type(), "Text"

QUnit.test "Text.cssType()", (assert)->
    assert.equal @text.type(), "Text"

QUnit.test "Text.blur()", (assert)->
    @region.attach(@text)

    @text.focus()
    assert.ok @text.isFocused()

    rootSpy = sinon.spy()
    @root.bind("blur", rootSpy)

    @text.blur()
    assert.notOk @text.isFocused()
    assert.ok rootSpy.calledWith(@text)

    @text.focus()

    @text.can("remove", false)
    @text.domElement().innerHTML = ""
    @text.content = new HTMLString("")

    @text.blur()
    assert.notStrictEqual @text.parent(), null

    @text.focus()

    @text.can("remove", true)
    @text.blur()
    assert.strictEqual @text.parent(), null

QUnit.test "Text.createDraggingDOMElement()", (assert)->
    @region.attach(@text)

    helper = @text.createDraggingDOMElement()

    assert.notStrictEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"
    assert.equal helper.innerHTML, "Lorem ipsum it dolor"

QUnit.test "Text.drag()", (assert)->
    @region.attach(@text)

    storeStateSpy = sinon.spy(@text, "storeState")
    startDraggingSpy = sinon.spy(@root, "startDragging")

    @text.drag(0, 0)

    assert.ok storeStateSpy.called
    assert.ok startDraggingSpy.called

    @root.cancelDragging()

QUnit.test "Text.drop()", (assert)->
    text2 = new Text(@root, "p", {}, "text2")
    @region.attach(@text)
    @region.attach(text2)

    restoreStateSpy = sinon.spy(@text, "restoreState")

    @text.storeState()
    @text.drop(text2, ["above", "center"])

    assert.ok restoreStateSpy.called

QUnit.test "Text.focus()", (assert)->
    @region.attach(@text)

    assert.notOk @text.isFocused()

    rootSpy = sinon.spy()
    @root.bind("focus", rootSpy)


    @text.focus()
    assert.ok @text.isFocused()
    assert.ok rootSpy.calledWith(@text)

QUnit.test "Text.html()", (assert)->
    text = new Text(@root, "p", {
        "class": "text-class",
        "style": "display: none;"
    }, "Lorem ipsum <b>it</b> dolor")
    assert.equal text.html(), (
        "<p class=\"text-class\" style=\"display: none;\">\n" +
        "#{config.INDENT}Lorem ipsum <b>it</b> dolor\n" +
        "</p>"
    )

QUnit.test "Text.mount()", (assert)->
    @region.attach(@text)
    @text.unmount()

    updateInnerHTMLSpy = sinon.spy(@text, "updateInnerHTML")

    rootSpy = sinon.spy()
    @root.bind("mount", rootSpy)

    @text.mount()

    assert.ok @text.isMounted()
    assert.ok updateInnerHTMLSpy.called
    assert.ok rootSpy.calledWith(@text)

QUnit.test "Text.restoreState()", (assert)->
    @region.attach(@text)

    @text.focus()
    new HTMLSelection(1, 2).select(@text.domElement())

    @text.storeState()
    @text.unmount()

    @text.mount()
    @text.restoreState()

    selection = HTMLSelection.query(@text.domElement())
    assert.deepEqual selection.get(), [1, 2]

QUnit.test "Text.selection()", (assert)->
    @region.attach(@text)

    @text.selection(new HTMLSelection(1, 2))
    assert.deepEqual @text.selection().get(), [1, 2]

QUnit.test "Text.storeState", (assert)->
    @region.attach(@text)

    @text.focus()
    new HTMLSelection(1, 2).select(@text.domElement())

    @text.storeState()
    assert.deepEqual @text._savedSelection.get(), [1, 2]

    @text.unmount()

    @text.mount()
    @text.restoreState()

    selection = HTMLSelection.query(@text.domElement())
    assert.deepEqual selection.get(), [1, 2]

QUnit.test "Text.updateInnerHTML()", (assert)->
    @region.attach(@text)

    @text.content = new HTMLString("new content")
    @text.updateInnerHTML()

    assert.equal @text.domElement().innerHTML, "new content"

QUnit.test "Text.fromDOMElement()", (assert)->
    content = "Lorem ipsum it dolor"
    for tagName in [
        "address"
        "blockquote"
        "h1"
        "h2"
        "h3"
        "h4"
        "h5"
        "h6"
        "p"
    ]
        domElement = document.createElement(tagName)
        domElement.innerHTML = content
        text = Text.fromDOMElement(@root, domElement)
        assert.equal text.html(), (
            "<#{tagName}>\n" +
            "#{config.INDENT}#{content}\n" +
            "</#{tagName}>"
        )

ev = preventDefault: -> return

buildTestRegion = (root)->
    el = document.getElementById("qunit-fixture")
    el.innerHTML = ""
    region = new Region(root, el)
    for i in [1, 2, 3]
        region.attach(new Text(root, "p", {}, "Content #{i}"))
    return region

focusAt = (text, begin, end)->
    text.focus()
    new HTMLSelection(begin, end).select(text.domElement())

focusAtStart = (text)->
    focusAt(text, 0, 0)

focusAtEnd = (text)->
    lastPosition = text.content.length()
    focusAt(text, lastPosition, lastPosition)

QUnit.test "Text._keyLeft()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    prevText = region.children[0]

    focusAtStart(text)
    text._keyLeft(ev)

    assert.equal @root.focused().id, prevText.id

QUnit.test "Text._keyUp()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    prevText = region.children[0]

    focusAtStart(text)
    text._keyUp(ev)

    assert.equal @root.focused().id, prevText.id

QUnit.test "Text._keyRight()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    nextText = region.children[2]

    focusAtEnd(text)
    text._keyRight(ev)

    assert.equal @root.focused().id, nextText.id

QUnit.test "Text._keyDown()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    nextText = region.children[2]

    focusAtEnd(text)
    text._keyDown(ev)

    assert.equal @root.focused().id, nextText.id

QUnit.test "Text._keyDelete()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    nextText = region.children[2]

    textContent = text.content.text()
    nextTextContent = nextText.content.text()

    focusAtEnd(text)
    text._keyDelete(ev)

    assert.equal text.content.text(), textContent + nextTextContent
    assert.equal region.children.length, 2

QUnit.test "Text._keyBack()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    prevText = region.children[0]

    textContent = text.content.text()
    prevTextContent = prevText.content.text()

    focusAtStart(text)
    text._keyBack(ev)

    assert.equal prevText.content.text(), prevTextContent + textContent
    assert.equal region.children.length, 2

QUnit.test "Text._keyReturn()", (assert)->
    region = buildTestRegion(@root)
    text = region.children[1]
    text.focus()

    content = text.content.text()
    lastPosition = text.content.length() - 1
    beforeLastChar = content.slice(0, lastPosition).replace(/\s+$/, "")
    lastChar = content[lastPosition]

    new HTMLSelection(lastPosition - 1, lastPosition - 1).select(text.domElement())
    text._keyReturn(ev)

    assert.equal region.children[1].content.text(), beforeLastChar
    assert.equal region.children[2].content.text(), lastChar
    assert.equal region.children.length, 4


    text = region.children[3]
    text.focus()

    content = text.content.text()

    lastPosition = text.content.length() - 1
    beforeLastChar = content.slice(0, lastPosition)
    lastChar = content[lastPosition]

    eventWithShift =
        preventDefault: -> return
        shiftKey: true

    new HTMLSelection(lastPosition, lastPosition).select(text.domElement())
    text._keyReturn(eventWithShift)

    assert.equal region.children[3].content.html(), "#{beforeLastChar}<br>#{lastChar}"
    assert.equal region.children.length, 4


    text = region.children[0]
    text.can("spawn", false)
    text.focus()

    contentText = text.content.text()
    lastPosition = text.content.length() - 1
    new HTMLSelection(lastPosition - 1, lastPosition - 1)
    text._keyReturn(ev)

    assert.equal region.children[0].content.text(), contentText
    assert.equal region.children.length, 4


QUnit.test "Text._keyReturn() & PREFER_LINE_BREAKS", (assert)->
    config.PREFER_LINE_BREAKS = true

    region = buildTestRegion(@root)
    text = region.children[0]
    text.focus()

    content = text.content.text()

    lastPosition = text.content.length() - 1
    beforeLastChar = content.slice(0, lastPosition)
    lastChar = content[lastPosition]

    new HTMLSelection(lastPosition, lastPosition).select(text.domElement())
    text._keyReturn(ev)

    assert.equal region.children[0].content.html(), "#{beforeLastChar}<br>#{lastChar}"
    assert.equal region.children.length, 3


    text = region.children[2]
    text.focus()

    content = text.content.text()
    lastPosition = text.content.length() - 1
    beforeLastChar = content.slice(0, lastPosition).replace(/\s+$/, "")
    lastChar = content[lastPosition]

    eventWithShift =
        preventDefault: -> return
        shiftKey: true

    new HTMLSelection(lastPosition, lastPosition).select(text.domElement())
    text._keyReturn(eventWithShift)

    assert.equal region.children[2].content.text(), beforeLastChar
    assert.equal region.children[3].content.text(), lastChar
    assert.equal region.children.length, 4

    config.PREFER_LINE_BREAKS = false

QUnit.test "Text.drop()", (assert)->
    otherText = new Text(@root, "p", {}, "OtherText")
    @region.attach(@text)
    @region.attach(otherText)

    assert.equal @text.nextSibling().id, otherText.id

    @text.drop(otherText, ["below", "center"])
    assert.equal otherText.nextSibling().id, @text.id

    @text.drop(otherText, ["above", "center"])
    assert.equal @text.nextSibling().id, otherText.id

    @region.detach(otherText)


    staticEl = Static.fromDOMElement(@root, document.createElement("div"))
    @region.attach(staticEl)

    assert.equal @text.nextSibling().id, staticEl.id

    @text.drop(staticEl, ["below", "center"])
    assert.equal staticEl.nextSibling().id, @text.id

    @text.drop(staticEl, ["above", "center"])
    assert.equal @text.nextSibling().id, staticEl.id

QUnit.test "Text.merge()", (assert)->
    @region.attach(@text)
    textHtml = @text.domElement().innerHTML

    otherTextHtml = "suffix <b>text</b>"
    otherText = new Text(@root, "p", {}, otherTextHtml)
    @region.attach(otherText)



    @text.merge(otherText)
    assert.equal @text.html(), (
        "<p>\n" +
        "#{config.INDENT}#{textHtml}#{otherTextHtml}\n" +
        "</p>"
    )
    assert.strictEqual otherText.parent(), null
