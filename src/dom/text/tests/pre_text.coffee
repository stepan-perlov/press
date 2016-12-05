QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")
Region = require("../../region/region.coffee")
PreText = require("../pre_text.coffee")
HTMLSelection = require("../../../html_selection/html_selection.coffee")

QUnit.module "press.dom.PreText",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.getElementById("qunit-fixture"))
        @preText = new PreText(@root, "pre", {}, "Lorem <b>ipsum</b> it dolor")

QUnit.test "PreText.type()", (assert)->
    assert.equal @preText.type(), "PreText"

QUnit.test "PreText.cssType()", (assert)->
    assert.equal @preText.cssType(), "pre-text"

QUnit.test "PreText.html()", (assert)->
    preText = new PreText @root, "pre", "class": "class-1", (
        "&lt;div&gt;" +
            " test &amp; test" +
        "&lt;/div&gt;"
    )
    assert.equal preText.html(), (
        "<pre class=\"class-1\">&lt;div&gt;" +
            " test &amp; test" +
        "&lt;/div&gt;</pre>"
    )

QUnit.test "PreText.fromDOMElement()", (assert)->
    preHtml = (
        "<pre>&lt;div&gt;" +
            " test &amp; test" +
        "&lt;/div&gt;</pre>"
    )
    domDiv = document.createElement("div")
    domDiv.innerHTML = preHtml

    preText = PreText.fromDOMElement(@root, domDiv.childNodes[0])
    assert.equal preText.html(), preHtml

QUnit.test "PreText._keyReturn()", (assert)->
    preText = new PreText(@root, "pre", {}, "Lorem ipsum it dolor")
    @region.attach(preText)
    preText.focus()
    preContentText = preText.content.text()
    lastIndex = preContentText.length - 1
    beforeLastChar = preContentText.slice(0, lastIndex)
    lastChar = preContentText[lastIndex]

    new HTMLSelection(lastIndex, lastIndex).select(preText.domElement())
    ev = preventDefault: -> return
    preText._keyReturn(ev)

    assert.equal preText.html(), "<pre>#{beforeLastChar}\n#{lastChar}</pre>"

QUnit.test "PreText.drop()", (assert)->
    otherPreText = new PreText(@root, "pre", {}, "")
    @region.attach(@preText)
    @region.attach(otherPreText)

    assert.equal @preText.nextSibling().id, otherPreText.id

    @preText.drop(otherPreText, ["below", "center"])
    assert.equal otherPreText.nextSibling().id, @preText.id

    @preText.drop(otherPreText, ["above", "center"])
    assert.equal @preText.nextSibling().id, otherPreText.id
