QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../config.coffee")
Root = require("../base/root.coffee")
Region = require("../region/region.coffee")
List = require("./list.coffee")
ListItem = require("./list_item.coffee")
ListItemText = require("./list_item_text.coffee")

QUnit.module "press.dom.ListItem",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))

QUnit.test "ListItem.type()", (assert)->
    listItem = new ListItem(@root)
    assert.equal listItem.type(), "ListItem"

QUnit.test "ListItem.cssType()", (assert)->
    listItem = new ListItem(@root)
    assert.equal listItem.cssType(), "list-item"

QUnit.test "ListItem.list()", (assert)->
    listItem = new ListItem(@root)
    assert.strictEqual listItem.list(), null

    list = new List(@root, "ul")
    listItem.attach(list)
    assert.strictEqual listItem.list(), null

    listItemText = new ListItemText(@root, "Text")
    listItem.attach(listItemText, 0)
    assert.equal listItem.list().id, list.id

QUnit.test "ListItem.listItemText()", (assert)->
    listItem = new ListItem(@root)
    assert.strictEqual listItem.listItemText(), null

    listItemText = new ListItemText(@root, "Text")
    listItem.attach(listItemText)
    assert.equal listItem.listItemText().id, listItemText.id

QUnit.test "ListItem.html()", (assert)->
    listItem = new ListItem(@root, "class": "class-1")
    listItemText = new ListItemText(@root, "Text")
    listItem.attach(listItemText)

    assert.equal listItem.html(), (
        "<li class=\"class-1\">\n" +
            "#{config.INDENT}Text\n" +
        "</li>"
    )

QUnit.test "ListItem.indent()", (assert)->
    I = config.INDENT
    textList = [1, 2, 3].map (i)-> "Text #{i}"

    domElement = document.createElement("ul")
    for text in textList
        domElement.innerHTML += "<li>#{text}</li>"
    list = List.fromDOMElement(@root, domElement)
    htmlBeforeIndent = list.html()

    list.children[0].indent()
    assert.equal list.html(), htmlBeforeIndent

    list.children[2].can("indent", false)
    list.children[2].indent()
    assert.equal list.html(), htmlBeforeIndent

    list.children[2].can("indent", true)
    list.children[2].indent()
    assert.equal list.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[0]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }</ul>\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[1].indent()
    assert.equal list.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[0]}\n" +
        "#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }#{ I }#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }#{ I }#{ I }</ul>\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }</ul>\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

QUnit.test "ListItem.unindent", (assert)->
    I = config.INDENT

    textList = [1, 2, 3, 4, 5, 6].map (i)-> "Text #{i}"

    domElement = document.createElement("ul")
    domElement.innerHTML = """
        <li>#{textList[0]}</li>
        <li>#{textList[1]}</li>
        <li>
            #{textList[2]}
            <ul>
                <li>
                    #{textList[3]}
                    <ul>
                        <li>#{textList[4]}</li>
                        <li>#{textList[5]}</li>
                    </ul>
                </li>
            </ul>
        </li>
    """
    list = List.fromDOMElement(@root, domElement)

    @region.attach(list)

    list.children[2].list().children[0].list().children[0].unindent()
    assert.equal @region.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[0]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[3]}\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[4]}\n" +
        "#{ I }#{ I }#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }#{ I }#{textList[5]}\n" +
        "#{ I }#{ I }#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }#{ I }#{ I }</ul>\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }</ul>\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[2].list().children[1].list().children[0].unindent()
    assert.equal @region.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[0]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[3]}\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[4]}\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }#{textList[5]}\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }</ul>\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[2].list().children[0].unindent()
    list.children[3].list().children[0].unindent()
    list.children[4].list().children[0].unindent()
    lastHtml = @region.html()

    assert.equal lastHtml, (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[0]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[3]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[4]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[5]}\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[0].can("indent", false)
    list.children[3].can("indent", false)
    list.children[0].unindent()
    list.children[3].unindent()

    assert.equal @region.html(), lastHtml

    list.children[0].can("indent", true)
    list.children[3].can("indent", true)
    list.children[0].unindent()
    list.children[2].unindent()

    assert.equal @region.html(), (
        "<p>\n" +
        "#{ I }#{textList[0]}\n" +
        "</p>\n" +
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[1]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[2]}\n" +
        "#{ I }</li>\n" +
        "</ul>\n" +
        "<p>\n" +
        "#{ I }#{textList[3]}\n" +
        "</p>\n" +
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[4]}\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }#{textList[5]}\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )


QUnit.test "ListItem.remove()", (assert)->
    I = config.INDENT

    domElement = document.createElement("ul")
    domElement.innerHTML = """
       <li>List 1 Item 1</li>
       <li>List 1 Item 2</li>
       <li>
            List 1 Item 3
            <ul>
                <li>List 2 Item 1</li>
                <li>List 2 Item 2</li>
            </ul>
       </li>
    """
    list = List.fromDOMElement(@root, domElement)

    list.children[2].list().children[1].remove()
    assert.equal list.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 1\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 2\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 3\n" +
        "#{ I }#{ I }<ul>\n" +
        "#{ I }#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }#{ I }List 2 Item 1\n" +
        "#{ I }#{ I }#{ I }</li>\n" +
        "#{ I }#{ I }</ul>\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[2].remove()
    assert.equal list.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 1\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 2\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 2 Item 1\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

    list.children[0].remove()
    assert.equal list.html(), (
        "<ul>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 1 Item 2\n" +
        "#{ I }</li>\n" +
        "#{ I }<li>\n" +
        "#{ I }#{ I }List 2 Item 1\n" +
        "#{ I }</li>\n" +
        "</ul>"
    )

QUnit.test "ListItem.fromDOMElement", (assert)->
    I = config.INDENT

    domElement = document.createElement("li")
    domElement.innerHTML = "text #1"
    listItem = ListItem.fromDOMElement(@root, domElement)
    assert.equal listItem.html(), (
        "<li>\n" +
        "#{ I }text #1\n" +
        "</li>"
    )

    domElement = document.createElement("li")
    domElement.innerHTML = """
        text #1
        <ul>
            <li>text #2</li>
        </ul>
    """
    listItem = ListItem.fromDOMElement(@root, domElement)
    assert.equal listItem.html(), (
        "<li>\n" +
        "#{ I }text #1\n" +
        "#{ I }<ul>\n" +
        "#{ I }#{ I }<li>\n" +
        "#{ I }#{ I }#{ I }text #2\n" +
        "#{ I }#{ I }</li>\n" +
        "#{ I }</ul>\n" +
        "</li>"
    )
