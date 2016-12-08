QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config")
Root = require("../../base/root")
Region = require("../../region/region")
List = require("../list")
ListItem = require("../list_item")
ListItemText = require("../list_item_text")

HTMLString = require("../../../html_string/html_string")
HTMLSelection = require("../../../html_selection/html_selection")

QUnit.module "press.dom.ListItemText",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))

QUnit.test "ListItemText.type()", (assert)->
    listItemText = new ListItemText(@root, "Lorem ipsum")
    assert.equal listItemText.type(), "ListItemText"

QUnit.test "ListItemText.cssType()", (assert)->
    listItemText = new ListItemText(@root, "Lorem ipsum")
    assert.equal listItemText.cssType(), "list-item-text"

QUnit.test "ListItemText.blur()", (assert)->
    el = document.getElementById("qunit-fixture")
    el.innerHTML = """
        <ul>
            <li>Text #1</li>
            <li>Text #2</li>
            <li>Text #3</li>
        </ul>
    """
    region = new Region(@root, el)
    list = region.children[0]
    listItem2 = list.children[1]
    text2 = listItem2.listItemText()

    text2.focus()
    assert.ok text2.isFocused()

    rootSpy = sinon.spy()
    @root.bind("blur", rootSpy)

    text2.blur()
    assert.notOk text2.isFocused()
    assert.ok rootSpy.calledWith(text2)

    text2.focus()

    listItem2.can("remove", false)
    text2.content = new HTMLString("")
    text2.blur()
    assert.equal list.children.length, 3

    text2.focus()

    listItem2.can("remove", true)
    text2.content = new HTMLString("")
    text2.blur()
    assert.equal list.children.length, 2

QUnit.test "ListItemText.html()", (assert)->
    textHtml = "Lorem <b>ipsum</b> it dolor"
    listItemText = new ListItemText(@root, textHtml)
    assert.equal listItemText.html(), textHtml

buildTestList = (root)->
    el = document.getElementById("qunit-fixture")
    el.innerHTML = """
        <ul>
            <li>Text #1</li>
            <li>Text #2</li>
            <li>Text #3</li>
        </ul>
    """
    region = new Region(root, el)
    return region.children[0]

ev = preventDefault: -> return

QUnit.test "ListItemText._keyReturn()", (assert)->
    list = buildTestList(@root)
    listItem = list.children[0]
    listItemText = listItem.listItemText()

    htmlBefore = list.html()

    contentText = listItemText.content.text()
    lastIndex = contentText.length - 1
    beforeLastChar = contentText.slice(0, lastIndex)
    lastChar = contentText[lastIndex]

    listItem.can("spawn", false)
    listItemText.focus()
    new HTMLSelection(lastIndex, lastIndex).select(listItemText.domElement())
    listItemText._keyReturn(ev)
    assert.equal htmlBefore, list.html()

    listItem.can("spawn", true)
    listItemText.focus()
    new HTMLSelection(lastIndex, lastIndex).select(listItemText.domElement())
    listItemText._keyReturn(ev)

    assert.equal listItemText.content.text(), beforeLastChar
    assert.equal listItem.nextSibling().listItemText().content.text(), lastChar

QUnit.test "ListItemText._keyTab()", (assert)->
    list = buildTestList(@root)
    listItem = list.children[0]
    listItemText = listItem.listItemText()

    indentSpy = sinon.spy(listItem, "indent")

    listItemText.focus()
    listItemText._keyTab(ev)

    assert.ok indentSpy.called

QUnit.test "ListItemText._keyTab(shiftKey: true)", (assert)->
    list = buildTestList(@root)
    listItem = list.children[0]
    listItemText = listItem.listItemText()

    unindentSpy = sinon.spy(listItem, "unindent")

    listItemText.focus()
    ev =
        preventDefault: -> return
        shiftKey: true
    listItemText._keyTab(ev)

    assert.ok unindentSpy.called

QUnit.test "ListItemText.drop(ListItemText)", (assert)->
    I = config.INDENT

    domElement = document.createElement("div")
    domElement.innerHTML = """
        <ul>
            <li>Text #1</li>
            <li>Text #2</li>
        </ul>
    """
    region = new Region(@root, domElement)
    list = region.children[0]
    listItemText1 = list.children[0].listItemText()
    listItemText2 = list.children[1].listItemText()

    listItemText1.drop(listItemText2, ["below", "middle"])
    assert.equal region.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }Text #2\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }Text #1\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    listItemText1.drop(listItemText2, ["above", "middle"])
    assert.equal region.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }Text #1\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }Text #2\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

QUnit.test "ListItemText.drop(Text)", (assert)->
    I = config.INDENT

    domElement = document.createElement("div")
    domElement.innerHTML = """
        <ul>
            <li>Text #1</li>
            <li>Text #2</li>
        </ul>
        <p>Text #3</p>
    """
    region = new Region(@root, domElement)
    listItemText = region.children[0].children[1].listItemText()
    text = region.children[1]

    listItemText.drop(text, ["below", "center"])
    assert.equal region.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }Text #1\n" +
        "#{ I }</li>\n" +
        "</ul>\n" +
        "<p>\n" +
        "#{ I }Text #3\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ I }Text #2\n" +
        "</p>"
    )

    listItemText = region.children[0].children[0].listItemText()
    text = region.children[2]
    listItemText.drop(text, ["below", "center"])
    assert.equal region.html(), (
        "<p>\n" +
        "#{ I }Text #3\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ I }Text #2\n" +
        "</p>\n" +
        "<p>\n" +
        "#{ I }Text #1\n" +
        "</p>"
    )

QUnit.test "ListItemText.merge(ListItemText)", (assert)->
    domElement = document.createElement("div")
    domElement.innerHTML = """
        <ul>
            <li>Apple</li>
            <li>-pen</li>
        </ul>
    """
    region = new Region(@root, domElement)
    list = region.children[0]
    listItemText1 = list.children[0].listItemText()
    listItemText2 = list.children[1].listItemText()

    listItemText1.merge(listItemText2)
    assert.equal listItemText1.html(), "Apple-pen"
    assert.equal list.children.length, 1

QUnit.test "ListItemText.merge(Text)", (assert)->
    domElement = document.createElement("div")
    domElement.innerHTML = """
        <ul>
            <li>Apple</li>
        </ul>
        <p>-pen</p>
    """

    region = new Region(@root, domElement)
    listItemText = region.children[0].children[0].listItemText()
    text = region.children[1]

    listItemText.merge(text)
    assert.equal listItemText.html(), "Apple-pen"
    assert.equal region.children.length, 1
