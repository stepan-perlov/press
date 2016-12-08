Element = require("../base/element")
ElementCollection = require("../base/element_collection")

TableCell = require("./table_cell")

class TableRow extends ElementCollection

    # An editable table row (e.g <tr>)

    constructor: (@root, attributes) ->
        super(@root, 'tr', attributes)

    # Read-only properties

    isEmpty: () ->
        # Return true if the row is empty of content
        for cell in @children
            text = cell.tableCellText()
            if text and text.content.length() > 0
                return false
        return true

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'TableRow'

    # Event handlers

    _onMouseOver: (ev) ->
        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Class properties

    @droppers:
        'TableRow': Element._dropVert

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type

        # Create the table row
        row = new @(root, @getDOMElementAttributes(domElement))

        # Create a list if child nodes we can safely remove whilst iterating
        # through them.
        childNodes = (c for c in domElement.childNodes)

        # Parse the section for rows
        for childNode in childNodes

            # Filter out non-elements
            unless childNode.nodeType == 1 # ELEMENT_NODE
                continue

            # Filter out non-<td/th> elements
            tagName = childNode.tagName.toLowerCase()
            unless tagName == 'td' or tagName == 'th'
                continue

            row.attach(TableCell.fromDOMElement(root, childNode))

        return row

module.exports = TableRow
