QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config")
Root = require("../../base/root")
Region = require("../../region/region")
Video = require("../video")
Image = require("../../image/image")
PreText = require("../../text/pre_text")
Text = require("../../text/text")
Static = require("../../static/static")

QUnit.module "press.dom.Video",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @video = new Video(@root, "video", {}, ["src": "fake.mp4"])

QUnit.test "Video.type()", (assert)->
    assert.equal @video.type(), "Video"

QUnit.test "Video.cssType()", (assert)->
    assert.equal @video.cssType(), "video"

QUnit.test "Video.createDraggingDOMElement()", (assert)->
    @region.attach(@video)
    helper = @video.createDraggingDOMElement()

    assert.notStrictEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"
    assert.equal helper.innerHTML, "fake.mp4"


    video = new Video(@root, "iframe", "src": "fake.mp4")
    @region.attach(video)

    helper = video.createDraggingDOMElement()

    assert.notStrictEqual helper, null
    assert.equal helper.tagName.toLowerCase(), "div"
    assert.equal helper.innerHTML, "fake.mp4"

QUnit.test "Video.html()", (assert)->
    video = new Video(@root, "video", {"controls": ""}, [
        {"src": "fake.mp4", "type": "video/mp4"},
        {"src": "fake.ogg", "type": "video/ogg"}
    ])
    assert.equal video.html(), (
        "<video controls>\n" +
        """#{ config.INDENT }<source src="fake.mp4" type="video/mp4">\n""" +
        """#{ config.INDENT }<source src="fake.ogg" type="video/ogg">\n""" +
        "</video>"
    )

    video = new Video(@root, "iframe", "src": "fake.mp4")
    assert.equal video.html(), """<iframe src="fake.mp4"></iframe>"""

QUnit.test "Video.mount()", (assert)->
    @region.attach(@video)

    @video.unmount()
    assert.notOk @video.isMounted()

    spyRoot = sinon.spy()
    @root.bind("mount", spyRoot)

    @video.mount()
    assert.ok @video.isMounted()
    assert.ok spyRoot.calledWith(@video)

QUnit.test "Video.fromDOMElement()", (assert)->
    domElement = document.createElement("video")
    domElement.setAttribute("controls", "")
    domElement.innerHTML = """
        <source src="fake.mp4" type="video/mp4">
        <source src="fake.ogg" type="video/ogg">
    """

    video = Video.fromDOMElement(@root, domElement)
    assert.equal video.html(), (
        "<video controls>\n" +
        """#{ config.INDENT }<source src="fake.mp4" type="video/mp4">\n""" +
        """#{ config.INDENT }<source src="fake.ogg" type="video/ogg">\n""" +
        "</video>"
    )


    domElement = document.createElement("iframe")
    domElement.setAttribute("src", "fake.mp4")

    video = Video.fromDOMElement(@root, domElement)
    assert.equal video.html(), """<iframe src="fake.mp4"></iframe>"""

QUnit.test "Video.drop(Video)", (assert)->
    otherVideo = new Video(@root, "iframe", "src": "fake2.mp4")
    @region.attach(@video)
    @region.attach(otherVideo)

    assert.equal @video.nextSibling().id, otherVideo.id

    @video.drop(otherVideo, ["above", "left"])
    assert.ok @video.hasCSSClass("align-left")
    assert.equal @video.nextSibling().id, otherVideo.id

    otherVideo.drop(@video, ["below", "right"])
    assert.ok @video.hasCSSClass("align-left")
    assert.ok otherVideo.hasCSSClass("align-right")
    assert.equal otherVideo.nextSibling().id, @video.id

    otherVideo.drop(@video, ["below", "center"])
    assert.ok @video.hasCSSClass("align-left")
    assert.notOk otherVideo.hasCSSClass("align-right")
    assert.equal @video.nextSibling().id, otherVideo.id

    @video.drop(otherVideo, ["below", "center"])
    assert.notOk @video.hasCSSClass("align-left")
    assert.equal otherVideo.nextSibling().id, @video.id

QUnit.test "Video.drop(Image)", (assert)->
    image = new Image(@root, "src": "fake.jpg")
    @region.attach(@video)
    @region.attach(image)

    assert.equal @video.nextSibling().id, image.id

    @video.drop(image, ["above", "right"])
    assert.ok @video.hasCSSClass("align-right")
    assert.equal @video.nextSibling().id, image.id

    @video.drop(image, ["below", "left"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.ok @video.hasCSSClass("align-left")
    assert.equal @video.nextSibling().id, image.id

    @video.drop(image, ["below", "center"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.notOk @video.hasCSSClass("align-left")
    assert.equal image.nextSibling().id, @video.id

QUnit.test "Video.drop(PreText)", (assert)->
    preText = new PreText(@root, "pre", {}, "PreText")
    @region.attach(@video)
    @region.attach(preText)

    assert.equal @video.nextSibling().id, preText.id

    @video.drop(preText, ["above", "right"])
    assert.ok @video.hasCSSClass("align-right")
    assert.equal @video.nextSibling().id, preText.id

    @video.drop(preText, ["below", "left"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.ok @video.hasCSSClass("align-left")
    assert.equal @video.nextSibling().id, preText.id

    @video.drop(preText, ["below", "center"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.notOk @video.hasCSSClass("align-left")
    assert.equal preText.nextSibling().id, @video.id

QUnit.test "Video.drop(Text)", (assert)->
    text = new Text(@root, "pre", {}, "Text")
    @region.attach(@video)
    @region.attach(text)

    assert.equal @video.nextSibling().id, text.id

    @video.drop(text, ["above", "right"])
    assert.ok @video.hasCSSClass("align-right")
    assert.equal @video.nextSibling().id, text.id

    @video.drop(text, ["below", "left"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.ok @video.hasCSSClass("align-left")
    assert.equal @video.nextSibling().id, text.id

    @video.drop(text, ["below", "center"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.notOk @video.hasCSSClass("align-left")
    assert.equal text.nextSibling().id, @video.id

QUnit.test "Video.drop(Static)", (assert)->
    staticElement = Static.fromDOMElement(@root, document.createElement("div"))
    @region.attach(@video)
    @region.attach(staticElement)

    assert.equal @video.nextSibling().id, staticElement.id

    @video.drop(staticElement, ["above", "right"])
    assert.ok @video.hasCSSClass("align-right")
    assert.equal @video.nextSibling().id, staticElement.id

    @video.drop(staticElement, ["below", "left"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.ok @video.hasCSSClass("align-left")
    assert.equal @video.nextSibling().id, staticElement.id

    @video.drop(staticElement, ["below", "center"])
    assert.notOk @video.hasCSSClass("align-right")
    assert.notOk @video.hasCSSClass("align-left")
    assert.equal staticElement.nextSibling().id, @video.id
