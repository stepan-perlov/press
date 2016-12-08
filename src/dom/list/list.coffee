classByTag = require("../class_by_tag")
Element = require("../base/element")
ElementCollection = require("../base/element_collection")
Text = require("../text/text")

ListItem = require("./list_item")

class List extends ElementCollection

    classByTag.associate(@, ['ol', 'ul'])

    constructor: (@root, tagName, attributes)->
        super(@root, tagName, attributes)

    # Read-only properties

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'List'

    # Event handlers

    _onMouseOver: (ev)->
        # Only support dropping on to the element if it sits at the top level
        if @parent().type() is 'ListItem'
            return

        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Class properties

    @droppers:
        'Image': Element._dropBoth
        'List': Element._dropVert
        'PreText': Element._dropVert
        'Static': Element._dropVert
        'Text': Element._dropVert
        'Video': Element._dropBoth

    # Class methods

    @fromDOMElement: (root, domElement)->
        # Convert an element (DOM) to an element of this type

        # Create the list
        list = new @(
            root,
            domElement.tagName,
            @getDOMElementAttributes(domElement)
        )

        # Create a list if child nodes we can safely remove whilst iterating
        # through them.
        childNodes = (c for c in domElement.childNodes)

        # Parse each item <li> in the list
        for childNode in childNodes

            # Filter out non-elements
            unless childNode.nodeType == 1 # ELEMENT_NODE
                continue

            # Filter out non-<li> elements
            unless childNode.tagName.toLowerCase() == 'li'
                continue

            # Parse the item
            list.attach(ListItem.fromDOMElement(root, childNode))

        # If the list is empty then don't create it
        if list.children.length == 0
            return null

        return list

module.exports = List
