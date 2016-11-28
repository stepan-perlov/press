QUnit = require("qunitjs")
sinon = require("sinon")

HTMLString = require("../../../html_string/html_string.coffee")
HTMLSelection = require("../../../html_selection/html_selection.coffee")
config = require("../../config.coffee")

Root = require("../../base/root.coffee")
Region = require("../../region/region.coffee")

Table = require("../table.coffee")
TableCellText = require("../table_cell_text.coffee")

QUnit.module "press.dom.TableCellText",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @tableCellText = new TableCellText(@root, "CellText")

QUnit.test "TableCellText.type()", (assert)->
    assert.equal @tableCellText.type(), "TableCellText"

QUnit.test "TableCellText.cssType()", (assert)->
    assert.equal @tableCellText.cssType(), "table-cell-text"

QUnit.test "TableCellText.blur()", (assert)->
    tableElement = document.createElement("table")
    tableElement.innerHTML = """
        <tbody>
            <tr>
                <td>Cell #1</td>
                <td>Cell #2</td>
            </tr>
        </tbody>
    """

    table = Table.fromDOMElement(@root, tableElement)
    @region.attach(table)

    tableCell = table.tbody().children[0].children[0]
    tableCellText = tableCell.tableCellText()

    tableCellText.focus()
    assert.ok tableCellText.isFocused()

    rootSpy = sinon.spy()
    @root.bind("blur", rootSpy)

    tableCellText.blur()
    assert.notOk tableCellText.isFocused()
    assert.ok rootSpy.calledWith(tableCellText)

    parent = tableCellText.parent()
    tableCellText.focus()

    tableCellText.content = new HTMLString("")
    tableCellText.blur()
    assert.equal parent.id, tableCellText.parent().id

QUnit.test "TableCellText.html()", (assert)->
    cellHtml = "Content <b># 1</b>"
    tableCellText = new TableCellText(@root, cellHtml)
    assert.equal tableCellText.html(), cellHtml

###
describe '`TableCellText` key events`', () ->

    INDENT = ContentEdit.INDENT
    ev = {preventDefault: () -> return}
    region = null
    table = null
    tbody = null

    beforeEach ->
        # Mount a text element to a region
        document.getElementById('test').innerHTML = '''
<p>foo</p>
<table>
    <tbody>
        <tr>
            <td>foo</td>
            <td>bar</td>
        </tr>
        <tr>
            <td>zee</td>
            <td>umm</td>
        </tr>
    </tbody>
</table>
<p>bar</p>
'''

        region = new factory.Region(document.getElementById('test'))
        table = region.children[1]
        tbody = table.tbody()

    afterEach ->
        for child in region.children.slice()
            region.detach(child)

    it 'should support down arrow nav to table cell below or next content \
        element if we\'re in the last row', () ->

        # Next cell down
        tableCellText = tbody.children[0].children[0].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())
        tableCellText._keyDown(ev)

        otherTableCellText = tbody.children[1].children[0].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

        # Next content element
        new ContentSelect.Range(3, 3).select(otherTableCellText.domElement())
        factory.root.focused()._keyDown(ev)
        expect(factory.root.focused()).toBe region.children[2]

    it 'should support up arrow nav to table cell below or previous content \
        element if we\'re in the first row', () ->

        # Previous cell up
        tableCellText = tbody.children[1].children[0].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(0, 0).select(tableCellText.domElement())
        tableCellText._keyUp(ev)

        otherTableCellText = tbody.children[0].children[0].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

        # Previous content element
        factory.root.focused()._keyUp(ev)
        expect(factory.root.focused()).toBe region.children[0]

    it 'should support return nav to next content element', () ->
        tableCellText = tbody.children[0].children[0].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())
        tableCellText._keyReturn(ev)

        otherTableCellText = tbody.children[0].children[1].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

    it 'should support using tab to nav to next table cell', () ->
        tableCellText = tbody.children[0].children[0].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())
        tableCellText._keyTab(ev)

        otherTableCellText = tbody.children[0].children[1].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

    it 'should support tab creating a new body row if last table cell in last \
        row of the table body focused', () ->

        rows = tbody.children.length
        tableCellText = tbody.children[1].children[1].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())
        tableCellText._keyTab(ev)

        expect(tbody.children.length).toBe rows + 1
        otherTableCellText = tbody.children[rows].children[0].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

    it 'should support using shift-tab to nav to previous table cell', () ->
        tableCellText = tbody.children[1].children[0].tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())

        ev.shiftKey = true
        tableCellText._keyTab(ev)

        otherTableCellText = tbody.children[0].children[1].tableCellText()
        expect(factory.root.focused()).toBe otherTableCellText

    it 'should not create an new body row on tab if spawn is disallowed', () ->

        rows = tbody.children.length
        tableCell = tbody.children[1].children[1]

        # Disallow spawning of new rows
        tableCell.can('spawn', false)

        tableCellText = tableCell.tableCellText()
        tableCellText.focus()
        new ContentSelect.Range(3, 3).select(tableCellText.domElement())
        tableCellText._keyTab(ev)

        expect(tbody.children.length).toBe rows
###
