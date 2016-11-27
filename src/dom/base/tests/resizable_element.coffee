QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../root.coffee")
ResizableElement = require("../resizable_element.coffee")
Region = require("../../region/region.coffee")

QUnit.module "press.dom.ResizableElement",
    beforeEach: ->
        @root = new Root()
        @element = new ResizableElement(@root, "div",
            "height": 200,
            "width": 200
        )

QUnit.test "ResizableElement.aspectRatio()", (assert)->
    assert.equal @element.aspectRatio(), 1

QUnit.test "ResizableElement.maxSize()", (assert)->
    assert.deepEqual @element.maxSize(), [
        config.DEFAULT_MAX_ELEMENT_WIDTH
        config.DEFAULT_MAX_ELEMENT_WIDTH
    ]

    @element.attr("data-ce-max-width", 1000)
    assert.deepEqual @element.maxSize(), [
        1000
        1000
    ]

QUnit.test "ResizableElement.minSize()", (assert)->
    assert.deepEqual @element.minSize(), [
        config.DEFAULT_MIN_ELEMENT_WIDTH
        config.DEFAULT_MIN_ELEMENT_WIDTH
    ]
    @element.attr("data-ce-min-width", 100)
    assert.deepEqual @element.minSize(), [
        100
        100
    ]

QUnit.test "ResizableElement.type()", (assert)->
    assert.equal @element.type(), "ResizableElement"

QUnit.test "ResizableElement.mount()", (assert)->
    region = new Region(@root, document.createElement("div"))
    region.attach(@element)

    unmountSpy = sinon.spy()
    @root.bind("unmount", unmountSpy)


    @element.unmount()
    assert.notOk @element.isMounted()
    assert.ok unmountSpy.calledWith(@element)

    mountSpy = sinon.spy()
    @root.bind("mount", mountSpy)

    @element.mount()
    assert.ok @element.isMounted()
    assert.ok mountSpy.calledWith(@element)

    size = @element.domElement().getAttribute("data-ce-size")
    assert.equal size, "w 200 × h 200"

QUnit.test "ResizableElement.resize()", (assert)->
    region = new Region(@root, document.createElement("div"))
    region.attach(@element)

    startResizingSpy = sinon.spy(@root, "startResizing")

    @element.resize(["top", "left"], 0, 0)

    assert.ok startResizingSpy.calledWith(
        @element,
        ["top", "left"]
        0,
        0,
        true # Fixed aspect ratio
    )

    startResizingSpy.reset()

    @element.can("resize", false)
    @element.resize(["top", "left"], 0, 0)

    assert.notOk startResizingSpy.called

QUnit.test "ResizableElement.size()", (assert)->
    assert.deepEqual @element.size(), [200, 200]

    @element.size([100, 100])
    assert.deepEqual @element.size(), [100, 100]
