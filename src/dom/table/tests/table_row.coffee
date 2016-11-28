QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")

Region = require("../../region/region.coffee")
Table = require("../table.coffee")
TableRow = require("../table_row.coffee")

QUnit.module "press.dom.TableRow",
    beforeEach: ->
        @root = new Root()

QUnit.test "TableRow.type()", (assert)->
    tableRow = new TableRow(@root)
    assert.equal tableRow.type(), "TableRow"

QUnit.test "TableRow.cssType()", (assert)->
    tableRow = new TableRow(@root)
    assert.equal tableRow.cssType(), "table-row"

QUnit.test "TableRow.isEmpty()", (assert)->
    domElement = document.createElement("tr")
    domElement.innerHTML = "<td></td><td></td>"

    tableRow = TableRow.fromDOMElement(@root, domElement)
    assert.equal tableRow.isEmpty(), true

    otherDomElement = document.createElement("tr")
    otherDomElement.innerHTML = "<td>Cell #1</td><td></td>"

    otherTableRow = TableRow.fromDOMElement(@root, otherDomElement)
    assert.equal otherTableRow.isEmpty(), false

QUnit.test "TableRow.fromDOMElement", (assert)->
    I = config.INDENT

    domElement = document.createElement("tr")
    domElement.innerHTML = """
        <td>Cell #1</td>
        <td>Cell #2</td>
    """

    tableRow = TableRow.fromDOMElement(@root, domElement)
    assert.equal tableRow.html(), (
        "<tr>\n" +
        "#{ I }<td>\n" +
        "#{ I }#{ I }Cell #1\n" +
        "#{ I }</td>\n" +
        "#{ I }<td>\n" +
        "#{ I }#{ I }Cell #2\n" +
        "#{ I }</td>\n" +
        "</tr>"
    )

ev = preventDefault: -> return
buildTable = (root)->
    region = new Region(root, document.createElement("div"))

    domElement = document.createElement("table")
    domElement.innerHTML = """
        <tbody>
            <tr>
                <td></td>
                <td></td>
            </tr>
            <tr>
                <td></td>
                <td>Cell #1</td>
            </tr>
        </tbody>
    """

    table = Table.fromDOMElement(root, domElement)
    region.attach(table)
    return table

QUnit.test "TableRow._keyDelete()", (assert)->
    table = buildTable(@root)
    tbody = table.children[0]
    firstRow = tbody.children[0]
    secondRow = tbody.children[1]

    firstRow.can("remove", false)
    text = firstRow.children[0].tableCellText()

    text.focus()
    text._keyBack(ev)
    assert.equal tbody.children.length, 2

    firstRow.can("remove", true)
    text.focus()
    text._keyBack(ev)
    assert.equal tbody.children.length, 1


    otherText = secondRow.children[1].tableCellText()
    otherText.focus()
    otherText._keyBack(ev)
    assert.equal tbody.children.length, 1

QUnit.test "TableRow._keyDelete()", (assert)->
    table = buildTable(@root)
    tbody = table.children[0]
    firstRow = tbody.children[0]
    secondRow = tbody.children[1]

    text = firstRow.children[0].tableCellText()
    text.focus()
    text._keyDelete(ev)
    assert.equal tbody.children.length, 1

    otherText = secondRow.children[1].tableCellText()
    otherText.focus()
    otherText._keyDelete(ev)
    assert.equal tbody.children.length, 1

QUnit.test "TableRow.drop()", (assert)->
    table = buildTable(@root)
    tbody = table.children[0]
    row = tbody.children[0]
    otherRow = tbody.children[1]

    assert.equal row.nextSibling().id, otherRow.id

    row.drop(otherRow, ["below", "center"])
    assert.equal otherRow.nextSibling().id, row.id

    row.drop(otherRow, ["above", "center"])
    assert.equal row.nextSibling().id, otherRow.id
