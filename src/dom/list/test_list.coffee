QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../config.coffee")
Root = require("../base/root.coffee")
Region = require("../region/region.coffee")
List = require("./list.coffee")
Image = require("../image/image.coffee")
PreText = require("../text/pre_text.coffee")
Text = require("../text/text.coffee")
Static = require("../static/static.coffee")
Video = require("../video/video.coffee")

QUnit.module "press.dom.List",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @list = new List(@root, "ul")

QUnit.test "List.type()", (assert)->
    assert.equal @list.type(), "List"

QUnit.test "List.cssType()", (assert)->
    assert.equal @list.cssType(), "list"

QUnit.test "List.fromDOMElement()", (assert)->
    domOl = document.createElement("ol")
    domOl.innerHTML = "<li>List Item 1</li>"
    ol = List.fromDOMElement(@root, domOl)
    assert.equal ol.html(), (
        "<ol>\n" +
        "#{config.INDENT}<li>\n" +
        "#{config.INDENT}#{config.INDENT}List Item 1\n" +
        "#{config.INDENT}</li>\n" +
        "</ol>"
    )

    domUl = document.createElement("ul")
    domUl.innerHTML = "<li>List Item N</li>"
    ul = List.fromDOMElement(@root, domUl)
    assert.equal ul.html(), (
        "<ul>\n" +
        "#{config.INDENT}<li>\n" +
        "#{config.INDENT}#{config.INDENT}List Item N\n" +
        "#{config.INDENT}</li>\n" +
        "</ul>"
    )

QUnit.test "List.drop(Image)", (assert)->
    image = new Image(@root, "src": "fake.jpg")
    @region.attach(@list)
    @region.attach(image)

    assert.equal @list.nextSibling().id, image.id

    @list.drop(image, ["below", "center"])
    assert.equal image.nextSibling().id, @list.id

    @list.drop(image, ["above", "center"])
    assert.equal @list.nextSibling().id, image.id

QUnit.test "List.drop(List)", (assert)->
    otherList = new List(@root, "ul")
    @region.attach(@list)
    @region.attach(otherList)

    assert.equal @list.nextSibling().id, otherList.id

    @list.drop(otherList, ["below", "center"])
    assert.equal otherList.nextSibling().id, @list.id

    @list.drop(otherList, ["above", "center"])
    assert.equal @list.nextSibling().id, otherList.id

QUnit.test "List.drop(PreText)", (assert)->
    preText = new PreText(@root, "pre", {}, "Content")
    @region.attach(@list)
    @region.attach(preText)

    assert.equal @list.nextSibling().id, preText.id

    @list.drop(preText, ["below", "center"])
    assert.equal preText.nextSibling().id, @list.id

    @list.drop(preText, ["above", "center"])
    assert.equal @list.nextSibling().id, preText.id

QUnit.test "List.drop(Text)", (assert)->
    text = new Text(@root, "p", {}, "Content")
    @region.attach(@list)
    @region.attach(text)

    assert.equal @list.nextSibling().id, text.id

    @list.drop(text, ["below", "center"])
    assert.equal text.nextSibling().id, @list.id

    @list.drop(text, ["above", "center"])
    assert.equal @list.nextSibling().id, text.id

QUnit.test "List.drop(Static)", (assert)->
    staticEl = Static.fromDOMElement(@root, document.createElement("div"))
    @region.attach(@list)
    @region.attach(staticEl)

    assert.equal @list.nextSibling().id, staticEl.id

    @list.drop(staticEl, ["below", "center"])
    assert.equal staticEl.nextSibling().id, @list.id

    @list.drop(staticEl, ["above", "center"])
    assert.equal @list.nextSibling().id, staticEl.id

QUnit.test "List.drop(Video)", (assert)->
    video = new Video(@root, "iframe", "src": "fake.jpg")
    @region.attach(@list)
    @region.attach(video)

    assert.equal @list.nextSibling().id, video.id

    @list.drop(video, ["below", "center"])
    assert.equal video.nextSibling().id, @list.id

    @list.drop(video, ["above", "center"])
    assert.equal @list.nextSibling().id, video.id
