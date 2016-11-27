QUnit = require("qunitjs")
sinon = require("sinon")
Root = require("../root.coffee")
Element = require("../element.coffee")
Region = require("../../region/region.coffee")
Image = require("../../image/image.coffee")
Text = require("../../text/text.coffee")

QUnit.module "press.dom.Element",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @element = new Element(@root, "div", {
            "class": "item"
            "data-test": "test"
        })

QUnit.test "Element.attributes()", (assert)->
    assert.deepEqual @element.attributes(), {
        "class": "item"
        "data-test": "test"
    }

QUnit.test "Element.cssType()", (assert)->
    assert.equal @element.cssType(), "element", "Should return `element`"

QUnit.test "Element.domElement()", (assert)->
    assert.equal @element.domElement(), null

    @region.attach(@element)

    assert.notEqual @element.domElement(), null

QUnit.test "Element.isFocused()", (assert)->
    assert.equal @element.isFocused(), false
    @element.focus()
    assert.equal @element.isFocused(), true

QUnit.test "Element.isMounted()", (assert)->
    assert.equal @element.isMounted(), false

    @region.attach(@element)

    assert.equal @element.isMounted(), true

QUnit.test "Element.type()", (assert)->
    assert.equal @element.type(), "Element"

QUnit.test "Element.addCSSClass()", (assert)->
    @element.addCSSClass("item2")
    assert.equal @element.hasCSSClass("item2"), true

    @element.addCSSClass("item3")
    assert.equal @element.hasCSSClass("item3"), true

QUnit.test "Element.attr()", (assert)->
    assert.equal @element.attr("data-test"), "test"
    @element.attr("data-test", "test2")
    assert.equal @element.attr("data-test"), "test2"

QUnit.test "Element.blur()", (assert)->
    @element.focus()
    assert.equal @element.isFocused(), true

    @element.blur()
    assert.equal @element.isFocused(), false

    spy = sinon.spy()
    @root.bind("blur", spy)

    @element.focus()
    @element.blur()

    assert.ok spy.calledWith(@element)

QUnit.test "Element.can()", (assert)->
    assert.equal @element.can("remove"), true
    @element.can("remove", false)
    assert.equal @element.can("remove"), false

QUnit.test "Element.createDraggingDOMElement()", (assert)->
    @region.attach(@element)

    helper = @element.createDraggingDOMElement()

    assert.notEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"

QUnit.test "Element.drag()", (assert)->
    @region.attach(@element)

    # should call `startDragging` against the root element
    spy = sinon.spy @root, "startDragging"
    @element.drag(0, 0)

    assert.ok spy.calledWith(@element, 0, 0)
    @root.cancelDragging()

    # should trigger the `drag` event against the root
    spy2 = sinon.spy()
    @root.bind("drag", spy2)

    @element.drag(0, 0)
    assert.ok spy2.calledWith(@element)
    @root.cancelDragging()

    # should do nothing if the `drag` behavior is not allowed
    root = new Root()
    element = new Element(root, "div")

    spy3 = sinon.spy root, "startDragging"
    element.can("drag", false)

    element.drag(0, 0)
    assert.notOk spy3.called

QUnit.test "Element.drop()", (assert)->
    imageA = new Image(@root)
    @region.attach(imageA)

    imageB = new Image(@root)
    @region.attach(imageB)

    spyDropper = sinon.spy Image.droppers, "Image"

    imageA.drop(imageB, ["below", "center"])
    assert.ok spyDropper.calledWith(
        imageA,
        imageB,
        ["below", "center"]
    ), "Should select a function from the elements droppers map"

    rootSpy = sinon.spy()
    @root.bind("drop", rootSpy)

    imageA.drop(imageB, ["below", "center"])
    assert.ok rootSpy.calledWith(
        imageA,
        imageB,
        ["below", "center"]
    ), "Should trigger the `drop` event against the root"

    imageA.drop(null, ["below", "center"])
    assert.ok rootSpy.calledWith(
        imageA,
        null,
        null
    ), "Should trigger the `drop` event against the root without params"

    spyDropper.reset()

    imageA.can("drop", false)
    imageA.drop(imageB, ["below", "center"])

    assert.notOk spyDropper.called

QUnit.test "Element.focus()", (assert)->
    @element.focus()
    assert.ok @element.isFocused()

    rootSpy = sinon.spy()
    @root.bind("focus", rootSpy)
    @element.blur()

    @element.focus()
    assert.ok rootSpy.calledWith(@element)

QUnit.test "Element.hasCSSClass()", (assert)->
    @element.addCSSClass("css-class-1")
    @element.addCSSClass("css-class-2")

    assert.ok @element.hasCSSClass("css-class-1")
    assert.ok @element.hasCSSClass("css-class-2")

QUnit.test "Element.merge()", (assert)->
    textA = new Text(@root, "p", {}, "Content A")
    textB = new Text(@root, "p", {}, "Content B")

    @region.attach(textA)
    @region.attach(textB)

    mergerSpy = sinon.spy(Text.mergers, "Text")

    textA.merge(textB)

    assert.ok mergerSpy.calledWith(textB, textA)

    mergerSpy.reset()

    textA.can("merge", false)
    textA.merge(textB)

    assert.notOk mergerSpy.called

QUnit.test "Element.mount()", (assert)->
    rootSpy = sinon.spy()
    @root.bind("mount", rootSpy)

    @region.attach(@element)
    @element.mount()

    assert.ok @element.isMounted()
    assert.ok rootSpy.calledWith(@element)

QUnit.test "Element.removeAttr()", (assert)->
    @element.attr("test-1", "test")
    assert.equal @element.attr("test-1"), "test"

    @element.removeAttr("test-1")
    assert.strictEqual @element.attr("test-1"), undefined

QUnit.test "Element.removeCSSClass()", (assert)->
    @element.addCSSClass("css-class-1")
    @element.addCSSClass("css-class-2")

    assert.ok @element.hasCSSClass("css-class-1")
    assert.ok @element.hasCSSClass("css-class-2")

    @element.removeCSSClass("css-class-1")
    @element.removeCSSClass("css-class-2")

    assert.notOk @element.hasCSSClass("css-class-1")
    assert.notOk @element.hasCSSClass("css-class-2")

QUnit.test "Element.tagName()", (assert)->
    assert.equal @element.tagName(), "div"

    @element.tagName("dt")

    assert.equal @element.tagName(), "dt"

QUnit.test "Element.unmount()", (assert)->
    @region.attach(@element)

    assert.ok @element.isMounted()

    rootSpy = sinon.spy()
    @root.bind("unmount", rootSpy)

    @element.unmount()

    assert.notOk @element.isMounted()
    assert.ok rootSpy.calledWith(@element)

QUnit.test "Element.@getDOMElementAttributes()", (assert)->
    attributes =
        "id": "id-1"
        "class": "css-class-1"
        "contenteditable": ""

    domElement = document.createElement("div")

    for key, value of attributes
        domElement.setAttribute(key, value)

    assert.deepEqual Element.getDOMElementAttributes(domElement), attributes
