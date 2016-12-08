QUnit = require("qunitjs")
sinon = require("sinon")
Root = require("../root")
Region = require("../../region/region")
Element = require("../element")
ResizableElement = require("../resizable_element")
Text = require("../../text/text")

QUnit.module "press.dom.Root",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @element = new Element(@root, "div")
        @region.attach(@element)

QUnit.test "Root.type", (assert)->
    assert.equal @root.type(), "Root"

QUnit.test "Root.focused()", (assert)->
    assert.strictEqual @root.focused(), null

    @element.focus()
    assert.equal @root.focused().id, @element.id

QUnit.test "Root.dragging()", (assert)->
    @element.drag(0, 0)
    assert.equal @root.dragging().id, @element.id

    @root.cancelDragging()
    assert.strictEqual @root.dragging(), null

QUnit.test "Root.dropTarget()", (assert)->
    element = new Text(@root, "p", {}, "Content")
    otherElement = new Text(@root, "p", {}, "Other Content")
    @region.attach(element)
    @region.attach(otherElement)

    element.drag(0, 0)
    otherElement._onMouseOver({})

    assert.equal @root.dropTarget().id, otherElement.id

    @root.cancelDragging()
    assert.strictEqual @root.dropTarget(), null

QUnit.test "Root.startDragging()", (assert)->
    @root.startDragging(@element, 0, 0)

    assert.equal @root.dragging().id, @element.id
    cssClasses = @element.domElement().getAttribute("class").split(" ")
    assert.notEqual cssClasses.indexOf("ce-element--dragging"), -1

    cssClasses = document.body.getAttribute("class").split(" ")
    assert.notEqual cssClasses.indexOf("ce--dragging"), -1

    assert.notStrictEqual @root._draggingDOMElement, null

QUnit.test "Root.cancelDragging", (assert)->
    @element.drag(0, 0)
    assert.equal @root.dragging().id, @element.id

    @root.cancelDragging()
    assert.strictEqual @root.dragging(), null

QUnit.test "Root.resizing()", (assert)->
    element = new ResizableElement(@root, "div")
    @region.attach(element)

    element.resize(["top", "left"], 0, 0)
    assert.equal @root.resizing().id, element.id

QUnit.test "Root.startResizing()", (assert)->
    element = new ResizableElement(@root, "div")
    @region.attach(element)

    @root.startResizing(element, ["top", "left"], 0, 0, true)

    assert.equal @root.resizing().id, element.id
    cssClasses = element.domElement().getAttribute("class").split(" ")
    assert.notEqual cssClasses.indexOf("ce-element--resizing"), -1

    cssClasses = document.body.getAttribute("class").split(" ")
    assert.notEqual cssClasses.indexOf("ce--resizing"), -1
