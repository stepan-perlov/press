ElementCollection = require("../base/element_collection.coffee")

TableRow = require("./table_row.coffee")

class TableSection extends ElementCollection

    constructor: (@root, tagName, attributes) ->
        super(@root, tagName, attributes)

    # Read-only properties

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'TableSection'

    # Event handlers

    _onMouseOver: (ev) ->
        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type

        # Create the table section
        section = new @(
            root,
            domElement.tagName,
            @getDOMElementAttributes(domElement)
        )

        # Create a list if child nodes we can safely remove whilst iterating
        # through them.
        childNodes = (c for c in domElement.childNodes)

        # Parse the section for rows
        for childNode in childNodes

            # Filter out non-elements
            unless childNode.nodeType == 1 # ELEMENT_NODE
                continue

            # Filter out non-<tr> elements
            unless childNode.tagName.toLowerCase() == 'tr'
                continue

            section.attach(TableRow.fromDOMElement(root, childNode))

        return section

module.exports = TableSection
