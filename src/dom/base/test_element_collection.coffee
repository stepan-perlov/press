QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../config.coffee")
Root = require("./root.coffee")
Element = require("./element.coffee")
ElementCollection = require("./element_collection.coffee")
Region = require("../region/region.coffee")
List = require("../list/list.coffee")
Text = require("../text/text.coffee")

INDENT = config.INDENT

QUnit.module "press.dom.ElementCollection",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))

QUnit.test "ElementCollection.cssType()", (assert)->
    element = new ElementCollection(@root, "div", "class": "css-class-1")
    assert.equal element.cssType(), "element-collection"

QUnit.test "ElementCollection.isMounted()", (assert)->
    collection = new List(@root, "ul")
    assert.notOk collection.isMounted()

    @region.attach(collection)
    assert.ok collection.isMounted()

QUnit.test "ElementCollection.html()", (assert)->
    collection = new ElementCollection(@root, "div", "class": "css-class-1")
    text = new Text(@root, "p", {}, "Paragraph text")
    collection.attach(text)

    assert.equal collection.html(), (
        "<div class=\"css-class-1\">\n" +
            "#{INDENT}<p>\n" +
                "#{INDENT}#{INDENT}Paragraph text\n" +
            "#{INDENT}</p>\n" +
        "</div>"
    )

QUnit.test "ElementCollection.type()", (assert)->
    collection = new ElementCollection(@root, "div", {})
    assert.equal collection.type(), "ElementCollection"

QUnit.test "ElementCollection.createDraggingDOMElement()", (assert)->
    collection = new ElementCollection(@root, "div")
    element = new Element(@root, "p")
    collection.attach(element)

    @region.attach(collection)

    helper = collection.createDraggingDOMElement()

    assert.notStrictEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"

QUnit.test "ElementCollection.detach()", (assert)->
    collection = new ElementCollection(@root, "div")
    elementA = new Element(@root, "p")
    elementB = new Element(@root, "p")

    @region.attach(collection)
    collection.attach(elementA)
    collection.attach(elementB)

    rootSpy = sinon.spy()
    @root.bind("detach", rootSpy)

    collection.detach(elementA)
    assert.equal collection.children.length, 1
    assert.ok rootSpy.calledWith(collection, elementA)

    collection.detach(elementB)
    assert.equal collection.children.length, 0
    assert.ok rootSpy.calledWith(collection, elementB)

QUnit.test "ElementCollection.mount()", (assert)->
    collection = new ElementCollection(@root, "div")
    element = new Element(@root, "p")

    @region.attach(collection)
    collection.attach(element)

    element.unmount()
    assert.notOk element.isMounted()

    rootSpy = sinon.spy()
    @root.bind("mount", rootSpy)

    collection.mount()

    assert.ok collection.isMounted()
    assert.ok element.isMounted()

    assert.ok rootSpy.calledWith(collection)
    assert.ok rootSpy.calledWith(element)

QUnit.test "ElementCollection.unmount()", (assert)->
    collection = new ElementCollection(@root, "div")
    element = new Element(@root, "p")

    @region.attach(collection)
    collection.attach(element)

    assert.ok collection.isMounted()
    assert.ok element.isMounted()

    rootSpy = sinon.spy()
    @root.bind("unmount", rootSpy)

    collection.unmount()

    assert.notOk collection.isMounted()
    assert.notOk element.isMounted()

    assert.ok rootSpy.calledWith(collection)
    assert.ok rootSpy.calledWith(element)
