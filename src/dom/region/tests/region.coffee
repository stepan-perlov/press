QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")
Region = require("../region.coffee")
Text = require("../../text/text.coffee")

QUnit.module "press.dom.Region",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))

QUnit.test "Region.type()", (assert)->
    assert.equal @region.type(), "Region"

QUnit.test "Region.domElement()", (assert)->
    domElement = document.createElement("div")
    region = new Region(@root, domElement)
    assert.equal region.domElement(), domElement

QUnit.test "Region.isMounted()", (assert)->
    assert.ok @region.isMounted()

QUnit.test "Region.html()", (assert)->
    @region.attach new Text(@root, "p", {}, "Text #1")
    @region.attach new Text(@root, "p", {}, "Text #2")
    @region.attach new Text(@root, "p", {}, "Text #3")
    @region.attach new Text(@root, "p", {}, "Text #4")

    assert.equal @region.html(), (
        "<p>\n" +
        "#{ config.INDENT }Text #1\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ config.INDENT }Text #2\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ config.INDENT }Text #3\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ config.INDENT }Text #4\n" +
        "</p>"
    )

QUnit.test "Region.setContent()", (assert)->
    domContent = document.createElement("div")
    domContent.innerHTML = "<p>Text #1</p>"

    @region.setContent(domContent)
    assert.equal @region.html(), (
        "<p>\n" +
        "#{ config.INDENT }Text #1\n" +
        "</p>"
    )

    stringContent = "<h1>Header #1</h1>"
    @region.setContent(stringContent)
    assert.equal @region.html(), (
        "<h1>\n" +
        "#{ config.INDENT }Header #1\n" +
        "</h1>"
    )
