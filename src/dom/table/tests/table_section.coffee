QUnit = require("qunitjs")
sinon = require("sinon")
config = require("../../config")
Root = require("../../base/root")

TableSection = require("../table_section")

QUnit.module "press.dom.TableSection",
    beforeEach: ->
        @root = new Root()
        @tableSection = new TableSection(@root, "tbody")

QUnit.test "TableSection.type()", (assert)->
    assert.equal @tableSection.type(), "TableSection"

QUnit.test "TableSection.cssType()", (assert)->
    assert.equal @tableSection.cssType(), "table-section"

QUnit.test "TableSection.fromDOMElement()", (assert)->
    I = config.INDENT

    for tagName in ["thead", "tbody", "tfoot"]
        domElement = document.createElement(tagName)
        domElement.innerHTML = """
            <tr>
                <td>Cell #1</td>
                <td>Cell #2</td>
            </tr>
        """

        tableSection = TableSection.fromDOMElement(@root, domElement)

        assert.equal tableSection.html(), (
            "<#{ tagName }>\n" +
            "#{ I }<tr>\n" +
            "#{ I }#{ I }<td>\n" +
            "#{ I }#{ I }#{ I }Cell #1\n" +
            "#{ I }#{ I }</td>\n" +
            "#{ I }#{ I }<td>\n" +
            "#{ I }#{ I }#{ I }Cell #2\n" +
            "#{ I }#{ I }</td>\n" +
            "#{ I }</tr>\n" +
            "</#{ tagName }>"
        )
