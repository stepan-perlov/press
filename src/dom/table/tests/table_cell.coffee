QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")

TableCell = require("../table_cell.coffee")
TableCellText = require("../table_cell_text.coffee")

QUnit.module "press.dom.TableCell",
    beforeEach: ->
        @root = new Root()
        @tableCell = new TableCell(@root, "td", {})

QUnit.test "TableCell.type()", (assert)->
    assert.equal @tableCell.type(), "TableCell"

QUnit.test "TableCell.cssType()", (assert)->
    assert.equal @tableCell.cssType(), "table-cell"

QUnit.test "TableCell.html()", (assert)->
    tableCell = new TableCell(@root, "th", "class": "table-cell")

    tableCellText = new TableCellText(@root, "Cell Text")
    tableCell.attach(tableCellText)

    assert.equal tableCell.html(), (
        """<th class="table-cell">\n""" +
        """#{ config.INDENT }Cell Text\n""" +
        """</th>"""
    )

QUnit.test "TableCell.fromDOMElement()", (assert)->
    tdElement = document.createElement("td")
    tdElement.innerHTML = "TD TEXT"

    tdTableCell = TableCell.fromDOMElement(@root, tdElement)
    assert.equal tdTableCell.html(), (
        "<td>\n" +
        "#{ config.INDENT }TD TEXT\n" +
        "</td>"
    )

    thElement = document.createElement("th")
    thElement.innerHTML = "TH TEXT"

    thTableCell = TableCell.fromDOMElement(@root, thElement)
    assert.equal thTableCell.html(), (
        "<th>\n" +
        "#{ config.INDENT }TH TEXT\n" +
        "</th>"
    )
