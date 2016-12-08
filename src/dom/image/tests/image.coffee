QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config")
Root = require("../../base/root")
Region = require("../../region/region")
Image = require("../image")
PreText = require("../../text/pre_text")
Text = require("../../text/text")
Static = require("../../static/static")

QUnit.module "press.dom.Image",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @image = new Image(@root, "src": "fake.jpg")

QUnit.test "Image.type()", (assert)->
    assert.equal @image.type(), "Image"

QUnit.test "Image.cssType()", (assert)->
    assert.equal @image.cssType(), "image"

QUnit.test "Image.createDraggingDOMElement()", (assert)->
    @region.attach(@image)

    helper = @image.createDraggingDOMElement()

    assert.notStrictEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"
    assert.equal helper.style.backgroundImage, """url("fake.jpg")"""

QUnit.test "Image.html()", (assert)->
    imageA = new Image(@root, "src": "imageA.jpg")
    assert.equal imageA.html(), """<img src="imageA.jpg">"""

    imageB = new Image(
        @root
        {"src": "imageB.jpg"}
        {"href": "full-size/imageB.jpg"}
    )
    assert.equal imageB.html(), (
        """<a href="full-size/imageB.jpg" data-ce-tag="img">\n""" +
        """#{ config.INDENT }<img src="imageB.jpg">\n""" +
        "</a>"
    )

QUnit.test "Image.mount()", (assert)->
    @region.attach(@image)

    @image.unmount()
    assert.notOk @image.isMounted()

    rootSpy = sinon.spy()
    @root.bind("mount", rootSpy)

    @image.mount()
    assert.ok @image.isMounted()
    assert.ok rootSpy.calledWith(@image)

QUnit.test "Image.fromDOMElement()", (assert)->
    domElement = document.createElement("img")
    domElement.setAttribute("src", "fake.jpg")
    domElement.setAttribute("width", "480")
    domElement.setAttribute("height", "640")

    image = Image.fromDOMElement(@root, domElement)
    assert.equal image.html(), """<img height="640" src="fake.jpg" width="480">"""

    # check natural size
    domElement = document.createElement("img")
    domElement.setAttribute("src", "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==")

    image = Image.fromDOMElement(@root, domElement)
    assert.deepEqual image.size(), [1, 1]

    # create with <a> wrapper
    domElement = document.createElement("img")
    domElement.setAttribute("src", "fake.jpg")
    domElement.setAttribute("width", 48)
    domElement.setAttribute("height", 48)

    domElementWrapper = document.createElement("a")
    domElementWrapper.setAttribute("href", "full-size/fake.jpg")
    domElementWrapper.appendChild(domElement)

    image = Image.fromDOMElement(@root, domElementWrapper)

    assert.equal image.html(), (
        """<a href="full-size/fake.jpg" data-ce-tag="img">\n""" +
        """#{ config.INDENT }<img height="48" src="fake.jpg" width="48">\n""" +
        "</a>"
    )

QUnit.test "Image.drop(Image)", (assert)->
    otherImage = new Image(@root, "src": "fake2.jpg")
    @region.attach(@image)
    @region.attach(otherImage)

    assert.equal @image.nextSibling().id, otherImage.id

    @image.drop(otherImage, ["above", "left"])
    assert.ok @image.hasCSSClass("align-left")
    assert.equal @image.nextSibling().id, otherImage.id

    otherImage.drop(@image, ["below", "right"])
    assert.ok @image.hasCSSClass("align-left")
    assert.ok otherImage.hasCSSClass("align-right")
    assert.equal otherImage.nextSibling().id, @image.id

    otherImage.drop(@image, ["below", "center"])
    assert.ok @image.hasCSSClass("align-left")
    assert.notOk otherImage.hasCSSClass("align-right")
    assert.equal @image.nextSibling().id, otherImage.id

    @image.drop(otherImage, ["below", "center"])
    assert.notOk @image.hasCSSClass("align-left")
    assert.equal otherImage.nextSibling().id, @image.id

QUnit.test "Image.drop(PreText)", (assert)->
    preText = new PreText(@root, "pre", {}, "Content")
    @region.attach(@image)
    @region.attach(preText)

    assert.equal @image.nextSibling().id, preText.id

    @image.drop(preText, ["above", "right"])
    assert.ok @image.hasCSSClass("align-right")
    assert.equal @image.nextSibling().id, preText.id

    @image.drop(preText, ["below", "left"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.ok @image.hasCSSClass("align-left")
    assert.equal @image.nextSibling().id, preText.id

    @image.drop(preText, ["below", "center"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.notOk @image.hasCSSClass("align-left")
    assert.equal preText.nextSibling().id, @image.id

QUnit.test "Image.drop(Text)", (assert)->
    text = new Text(@root, "p", {}, "Content")
    @region.attach(@image)
    @region.attach(text)

    assert.equal @image.nextSibling().id, text.id

    @image.drop(text, ["above", "right"])
    assert.ok @image.hasCSSClass("align-right")
    assert.equal @image.nextSibling().id, text.id

    @image.drop(text, ["below", "left"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.ok @image.hasCSSClass("align-left")
    assert.equal @image.nextSibling().id, text.id

    @image.drop(text, ["below", "center"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.notOk @image.hasCSSClass("align-left")
    assert.equal text.nextSibling().id, @image.id

QUnit.test "Image.drop(Static)", (assert)->
    staticElement = Static.fromDOMElement(@root, document.createElement('div'))
    @region.attach(@image)
    @region.attach(staticElement)

    assert.equal @image.nextSibling().id, staticElement.id

    @image.drop(staticElement, ["above", "right"])
    assert.ok @image.hasCSSClass("align-right")
    assert.equal @image.nextSibling().id, staticElement.id

    @image.drop(staticElement, ["below", "left"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.ok @image.hasCSSClass("align-left")
    assert.equal @image.nextSibling().id, staticElement.id

    @image.drop(staticElement, ["below", "center"])
    assert.notOk @image.hasCSSClass("align-right")
    assert.notOk @image.hasCSSClass("align-left")
    assert.equal staticElement.nextSibling().id, @image.id
