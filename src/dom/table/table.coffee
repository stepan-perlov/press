classByTag = require("../class_by_tag")
Element = require("../base/element")
ElementCollection = require("../base/element_collection")

TableSection = require("./table_section")
TableRow = require("./table_row")

class Table extends ElementCollection

    classByTag.associate(@, ["table"])

    # An editable table (e.g <table>)

    constructor: (@root, attributes) ->
        super(@root, 'table', attributes)

    # Read-only properties

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'Table'

    firstSection: () ->
        # Return the first table section associted with the table (if there is
        # one).
        if section = @thead()
            return section
        else if section =  @tbody()
            return section
        else if section = @tfoot()
            return section
        return null

    lastSection: () ->
        # Return the last table section associted with the table (if there is
        # one).
        if section = @tfoot()
            return section
        else if section =  @tbody()
            return section
        else if section = @thead()
            return section
        return null

    tbody: () ->
        # Return the table body associated with the table (if there is one)
        return @_getChild('tbody')

    tfoot: () ->
        # Return the table footer associated with the table (if there is one)
        return @_getChild('tfoot')

    thead: () ->
        # Return the table header associated with the table (if there is one)
        return @_getChild('thead')

    # Event handlers

    _onMouseOver: (ev) ->
        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Private methods

    _getChild: (tagName) ->
        # Return a child of the table that matches the specified tag name
        for child in @children
            if child.tagName() == tagName
                return child
        return null

    # Class properties

    @droppers:
        'Image': Element._dropBoth
        'List': Element._dropVert
        'PreText': Element._dropVert
        'Static': Element._dropVert
        'Table': Element._dropVert
        'Text': Element._dropVert
        'Video': Element._dropBoth

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type

        # Create the table
        table = new @(root, @getDOMElementAttributes(domElement))

        # Create a list if child nodes we can safely remove whilst iterating
        # through them.
        childNodes = (c for c in domElement.childNodes)

        # Parse the table for sections and rows
        orphanRows = []
        for childNode in childNodes

            # Filter out non-elements
            unless childNode.nodeType == 1 # ELEMENT_NODE
                continue

            # Don't allow duplicate sections
            tagName = childNode.tagName.toLowerCase()
            if table._getChild(tagName)
                continue

            # Convert relevent child nodes
            switch tagName

                when 'tbody', 'tfoot', 'thead'
                    section = TableSection.fromDOMElement(root, childNode)
                    table.attach(section)

                when 'tr'
                    row = TableRow.fromDOMElement(root, childNode)
                    orphanRows.push(row)

        # If there are orphan rows
        if orphanRows.length > 0
            if not table._getChild('tbody')
                table.attach(new TableSection(root, 'tbody'))

            for row in orphanRows
                table.tbody().attach(row)

        # If the table is empty then don't create it
        if table.children.length == 0
            return null

        return table

module.exports = Table
