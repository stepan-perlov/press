config = require("../config")
ElementCollection = require("../base/element_collection")

TableCellText = require("./table_cell_text")

class TableCell extends ElementCollection

    # An editable table cell (e.g <td>, <th>).

    constructor: (@root, tagName, attributes) ->
        super(@root, tagName, attributes)

    # Read-only properties

    tableCellText: () ->
        # Return the table cell text associated with this table cell (if there
        # is one).
        if @children.length > 0
            return @children[0]
        return null

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'TableCell'

    # Methods

    html: (indent='') ->
        lines = [
            "#{ indent }<#{ @tagName() }#{ @_attributesToString() }>"
            ]
        if @tableCellText()
            lines.push(@tableCellText().html(indent + config.INDENT))
        lines.push("#{ indent }</#{ @tagName() }>")
        return lines.join('\n')

    # Event handlers

    _onMouseOver: (ev) ->
        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Disabled methods

    _addDOMEventListeners: () ->
    _removeDOMEventListners: () ->

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type
        tableCell = new @(
            root,
            domElement.tagName
            @getDOMElementAttributes(domElement)
            )

        # Attach a table cell text item
        tableCellText = new TableCellText(
            root,
            domElement.innerHTML.replace(/^\s+|\s+$/g, '')
        )
        tableCell.attach(tableCellText)

        return tableCell

module.exports = TableCell
