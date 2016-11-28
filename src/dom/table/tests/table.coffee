QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config.coffee")
Root = require("../../base/root.coffee")
Region = require("../../region/region.coffee")

Table = require("../table.coffee")
TableSection = require("../table_section.coffee")

Text = require("../../text/text.coffee")
PreText = require("../../text/pre_text.coffee")
List = require("../../list/list.coffee")
Image = require("../../image/image.coffee")
Video = require("../../video/video.coffee")

QUnit.module "press.dom.Table",
    beforeEach: ->
        @root = new Root()
        @region = new Region(@root, document.createElement("div"))
        @table = new Table(@root)

QUnit.test "Table.type()", (assert)->
    assert.equal @table.type(), "Table"

QUnit.test "Table.cssType()", (assert)->
    assert.equal @table.cssType(), "table"

QUnit.test "Table.firstSection()", (assert)->
    thead = new TableSection(@root, "thead")
    tbody = new TableSection(@root, "tbody")
    tfoot = new TableSection(@root, "tfoot")

    assert.strictEqual @table.firstSection(), null

    @table.attach(tfoot)
    assert.equal @table.firstSection().id, tfoot.id

    @table.attach(tbody)
    assert.equal @table.firstSection().id, tbody.id

    @table.attach(thead)
    assert.equal @table.firstSection().id, thead.id

QUnit.test "Table.lastSection()", (assert)->
    thead = new TableSection(@root, "thead")
    tbody = new TableSection(@root, "tbody")
    tfoot = new TableSection(@root, "tfoot")

    @table.attach(tbody)
    assert.equal @table.lastSection().id, tbody.id

    @table.attach(thead)
    assert.equal @table.lastSection().id, tbody.id

    @table.attach(tfoot)
    assert.equal @table.lastSection().id, tfoot.id

QUnit.test "Table.thead()", (assert)->
    assert.strictEqual @table.thead(), null

    thead = new TableSection(@root, "thead")

    @table.attach(thead)
    assert.equal @table.thead().id, thead.id

QUnit.test "Table.tbody()", (assert)->
    assert.strictEqual @table.tbody(), null

    tbody = new TableSection(@root, "tbody")

    @table.attach(tbody)
    assert.equal @table.tbody().id, tbody.id

QUnit.test "Table.tfoot()", (assert)->
    assert.strictEqual @table.tfoot(), null

    tfoot = new TableSection(@root, "tfoot")

    @table.attach(tfoot)
    assert.equal @table.tfoot().id, tfoot.id

QUnit.test "Table.fromDOMElement()", (assert)->
    I = config.INDENT

    domTable = document.createElement("table")
    domTable.innerHTML = """
        <tbody>
            <tr>
                <td>Cell #1</td>
                <td>Cell #2</td>
            </tr>
        </tbody>
    """

    table = Table.fromDOMElement(@root, domTable)
    assert.equal table.html(), (
        "<table>\n" +
        "#{ I }<tbody>\n" +
        "#{ I }#{ I }<tr>\n" +
        "#{ I }#{ I }#{ I }<td>\n" +
        "#{ I }#{ I }#{ I }#{ I }Cell #1\n" +
        "#{ I }#{ I }#{ I }</td>\n" +
        "#{ I }#{ I }#{ I }<td>\n" +
        "#{ I }#{ I }#{ I }#{ I }Cell #2\n" +
        "#{ I }#{ I }#{ I }</td>\n" +
        "#{ I }#{ I }</tr>\n" +
        "#{ I }</tbody>\n" +
        "</table>"
    )

    otherDomTable = document.createElement("table")
    otherDomTable.innerHTML = """
        <tr>
            <td>Cell #1</td>
            <td>Cell #2</td>
        </tr>
    """

    otherTable = Table.fromDOMElement(@root, otherDomTable)
    assert.equal otherTable.html(), table.html()

QUnit.test "Table.drop(Text)", (assert)->
    text = new Text(@root, "p")
    @region.attach(@table)
    @region.attach(text)

    assert.equal @table.nextSibling().id, text.id

    @table.drop(text, ["below", "center"])
    assert.equal text.nextSibling().id, @table.id

    @table.drop(text, ["above", "center"])
    assert.equal @table.nextSibling().id, text.id

QUnit.test "Table.drop(PreText)", (assert)->
    preText = new PreText(@root, "pre", {}, "Content")
    @region.attach(@table)
    @region.attach(preText)

    assert.equal @table.nextSibling().id, preText.id

    @table.drop(preText, ["below", "center"])
    assert.equal preText.nextSibling().id, @table.id

    @table.drop(preText, ["above", "center"])
    assert.equal @table.nextSibling().id, preText.id

QUnit.test "Table.drop(List)", (assert)->
    list = new List(@root, "ul")
    @region.attach(@table)
    @region.attach(list)

    assert.equal @table.nextSibling().id, list.id

    @table.drop(list, ["below", "center"])
    assert.equal list.nextSibling().id, @table.id

    @table.drop(list, ["above", "center"])
    assert.equal @table.nextSibling().id, list.id

QUnit.test "Table.drop(Image)", (assert)->
    image = new Image(@root, "src": "fake.jpg")
    @region.attach(@table)
    @region.attach(image)

    assert.equal @table.nextSibling().id, image.id

    @table.drop(image, ["below", "center"])
    assert.equal image.nextSibling().id, @table.id

    @table.drop(image, ["above", "center"])
    assert.equal @table.nextSibling().id, image.id

QUnit.test "Table.drop(Text)", (assert)->
    video = new Video(@root, "iframe", "src": "fake.mp4")
    @region.attach(@table)
    @region.attach(video)

    assert.equal @table.nextSibling().id, video.id

    @table.drop(video, ["below", "center"])
    assert.equal video.nextSibling().id, @table.id

    @table.drop(video, ["above", "center"])
    assert.equal @table.nextSibling().id, video.id
