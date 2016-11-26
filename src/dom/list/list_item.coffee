HtmlSelection = require("../../html_selection/html_selection.coffee")
HtmlString = require("../../html_string/html_string.coffee")

config = require("../config.coffee")
ElementCollection = require("../base/element_collection.coffee")

Text = require("../text/text.coffee")
ListItemText = require("./list_item_text.coffee")

class ListItem extends ElementCollection

    constructor: (@root, attributes)->
        super(@root, 'li', attributes)

        # Add the indent behaviour for list items
        @_behaviours['indent'] = true

    # Read-only properties

    list: ->
        # Return the list associated with this list item (if there is one)
        if @children.length == 2
            return @children[1]
        return null

    listItemText: ->
        # Return the list item text associated with this list item (if there is
        # one).
        if @children.length > 0
            return @children[0]
        return null

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'ListItem'

    # Methods

    html: (indent='')->
        lines = [
            "#{ indent }<li#{ @_attributesToString() }>"
            ]
        if @listItemText()
            lines.push(@listItemText().html(indent + config.INDENT))
        if @list()
            lines.push(@list().html(indent + config.INDENT))
        lines.push("#{ indent }</li>")
        return lines.join('\n')

    indent: ->
        # Indent the list item
        unless @can('indent')
            return

        # The first item in a list can't be indented
        if @parent().children.indexOf(this) == 0
            return

        # Add the item to the previous items list, if the previous item doesn't
        # have a list add one.
        sibling = @previousSibling()
        unless sibling.list()
            tagName = sibling.parent().tagName()
            List = require("./list.coffee")
            sibling.attach new List(@root, tagName)

        @listItemText().storeState()

        @parent().detach(this)
        sibling.list().attach(this)

        @listItemText().restoreState()

    remove: ->
        # Remove the item from the list
        unless @parent()
            return

        index = @parent().children.indexOf(this)

        # If the list item has children move them into the parent list
        if @list()
            # NOTE: `slice` used to create a copy for safe iteration
            # over a changing list.
            for child, i in @list().children.slice()
                child.parent().detach(child)
                @parent().attach(child, i + index)
        @parent().detach(this)

    unindent: ->
        # Unindent the list item
        unless @can('indent')
            return

        parent = @parent()
        grandParent = parent.parent()

        # Extract a list of all the siblings that follow the item
        siblings = parent.children.slice(
            parent.children.indexOf(this) + 1,
            parent.children.length
            )

        List = require("./list.coffee")

        if grandParent.type() is 'ListItem'
            # Move the item to the same level as it's parent
            @listItemText().storeState()

            # Move the item into it's parents list
            parent.detach(this)
            grandParent.parent().attach(
                this,
                grandParent.parent().children.indexOf(grandParent) + 1
                )

            # Indent all the siblings that follow the item so that they become
            # it's children.
            if siblings.length and not @list()
                tagName = parent.tagName()
                @attach new List(@root, tagName)

            for sibling in siblings
                sibling.parent().detach(sibling)
                @list().attach(sibling)

            @listItemText().restoreState()

        else
            # Cast the item as a text element (<P>)
            text = new Text(
                @root,
                'p',
                if @attr('class') then {'class': @attr('class')} else {},
                @listItemText().content
            )

            # Remember the current selection (if focused so we can restore after
            # performing the indent.
            selection = null
            if @listItemText().isFocused()
                selection = HtmlSelection.query(
                    @listItemText().domElement()
                    )

            # Before we remove the list item determine the index to insert the
            # replacement text element at.
            parentIndex = grandParent.children.indexOf(parent)
            itemIndex = parent.children.indexOf(this)

            # First or only - insert the new text element before the grand
            # parent.
            if itemIndex == 0

                # If this is the only element in the list remove the list else
                # just the item.
                list = null
                if parent.children.length == 1
                    # If there are children then we need to create a new list to
                    # insert them into once the items parent has been detached.
                    if @list()
                        tagName = parent.tagName()
                        list = new List(@root, tagName)

                    grandParent.detach(parent)

                else
                    parent.detach(this)

                # Insert the converted text element (and new list if there is
                # one).
                grandParent.attach(text, parentIndex)
                if list
                    grandParent.attach(list, parentIndex + 1)

                # If the list item has children move them into the parent list
                if @list()
                    # NOTE: `slice` used to create a copy for safe iteration
                    # over a changing list.
                    for child, i in @list().children.slice()
                        child.parent().detach(child)
                        if list
                            list.attach(child)
                        else
                            parent.attach(child, i)

            # Last - insert the new text element after the grand parent
            else if itemIndex == parent.children.length - 1

                # Insert the converted text element
                parent.detach(this)
                grandParent.attach(text, parentIndex + 1)

                # If the list item has children insert them as a new list in the
                # grand parent.
                if @list()
                    grandParent.attach(@list(), parentIndex + 2)

            # Middle - split the parent list and insert the element between
            else

                # Insert the converted text element
                parent.detach(this)
                grandParent.attach(text, parentIndex + 1)

                # Move the children and siblings to a new list after the new
                # text element
                tagName = parent.tagName()
                list = new List(@root, tagName)
                grandParent.attach(list, parentIndex + 2)

                # Children
                if @list()
                    # NOTE: `slice` used to create a copy for safe iteration
                    # over a changing list.
                    for child in @list().children.slice()
                        child.parent().detach(child)
                        list.attach(child)

                # Siblings
                for sibling in siblings
                    sibling.parent().detach(sibling)
                    list.attach(sibling)

            # Restore selection
            if selection
                text.focus()
                selection.select(text.domElement())

    # Event handlers

    _onMouseOver: (ev)->
        super(ev)

        # Don't highlight that we're over the element
        @_removeCSSClass('ce-element--over')

    # Disabled methods

    _addDOMEventListeners: ->
    _removeDOMEventListners: ->

    # Class methods

    @fromDOMElement: (root, domElement)->
        List = require("./list.coffee")
        # Convert an element (DOM) to an element of this type

        # Create the list item
        listItem = new @(root, @getDOMElementAttributes(domElement))

        # Build the text content for the list item by iterating over the nodes
        # and ignoring any lists. If we do find lists, keep a reference to the
        # first one (we only allow one list per list item) so that we can add it
        # next.
        content = ''
        listDOMElement = null
        for childNode in domElement.childNodes
            if childNode.nodeType == 1 # ELEMENT_NODE

                # Check for lists
                if childNode.tagName.toLowerCase() in ['ul', 'li']

                    # Keep a reference to the first list found
                    if not listDOMElement
                        listDOMElement = childNode

                else
                    content += childNode.outerHTML
            else
                content += HtmlString.encode(childNode.textContent)

        content = content.replace(/^\s+|\s+$/g, '')

        listItemText = new ListItemText(root, content)
        listItem.attach(listItemText)

        # List
        if listDOMElement
            listElement = List.fromDOMElement(root, listDOMElement)
            listItem.attach(listElement)

        return listItem

module.exports = ListItem
