HtmlString = require("../../html_string/html_string.coffee")
HtmlSelection = require("../../html_selection/html_selection.coffee")
classByTag = require("../class_by_tag.coffee")
Element = require("../base/element.coffee")
ElementCollection = require("../base/element_collection.coffee")
Text = require("../text/text.coffee")
config = require("../config.coffee")

moduleClasses = {}

class moduleClasses.List extends ElementCollection

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
            list.attach(new moduleClasses.ListItem.fromDOMElement(root, childNode))

        # If the list is empty then don't create it
        if list.children.length == 0
            return null

        return list

#---------------------------------------------------------------------------------
#
#
# ListItem
#
#
#---------------------------------------------------------------------------------

class moduleClasses.ListItem extends ElementCollection

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
            sibling.attach new moduleClasses.List(@root, tagName)

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
                @attach new moduleClasses.List(@root, tagName)

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
                        list = new moduleClasses.List(@root, tagName)

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
                list = new moduleClasses.List(@root, tagName)
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

        listItemText = new moduleClasses.ListItemText(root, content)
        listItem.attach(listItemText)

        # List
        if listDOMElement
            listElement = moduleClasses.List.fromDOMElement(root, listDOMElement)
            listItem.attach(listElement)

        return listItem

#---------------------------------------------------------------------------------
#
#
# ListItem
#
#
#---------------------------------------------------------------------------------

class ListItemText extends Text

    constructor: (content)->
        super('div', {}, content)

    # Read-only properties

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'ListItemText'

    # Methods

    blur: ->
        # Remove focus from the element

        # Remove editing focus from this element
        if @content.isWhitespace() and @can('remove')

            # Remove parent list item if empty
            @parent().remove()

        else if @isMounted()
            # Blur the DOM element
            @_domElement.blur()

            # Stop the element from being editable
            @_domElement.removeAttribute('contenteditable')

        Element::blur.call(@)

    can: (behaviour, allowed) ->
        # The allowed behaviour for a ListItemText instance reflects its parent
        # ListItem and can not be set directly.
        if allowed
            throw new Error('Cannot set behaviour for ListItemText')

        return @parent().can(behaviour)

    html: (indent='') ->
        # Return a HTML string for the node

        # For text elements with optimized output we use a cache to improve
        # performance for repeated calls.
        if not @_lastCached or @_lastCached < @_modified

            # Optimize the content for output
            content = @content.copy().trim()
            content.optimize()

            @_lastCached = Date.now()
            @_cached = content.html()

        return "#{ indent }#{ @_cached }"

    # Event handlers

    _onMouseDown: (ev) ->
        # Give the element focus
        Element::_onMouseDown.call(@, ev)

        # Lists support dragging of list items or the root list. The drag is
        # initialized by clicking and holding the mouse down on a list item text
        # element, how long the user holds the mouse down determines which
        # element is dragged (the parent list item or the list root).
        initDrag = () =>
            if @root.dragging() == this
                # We're currently dragging the list item so switch to dragging
                # the list root.

                # Cancel dragging the list item
                @root.cancelDragging()

                # Find the list root and start dragging it
                listRoot = @closest (node) ->
                    return node.parent().type() == 'Region'
                listRoot.drag(ev.pageX, ev.pageY)

            else
                # We're not currently dragging anything so start dragging the
                # list item.
                @drag(ev.pageX, ev.pageY)

                # Reset a timeout for this function so that if the user
                # continues to hold down the mouse we can switch to the list
                # root.
                @_dragTimeout = setTimeout(
                    initDrag,
                    config.DRAG_HOLD_DURATION * 2
                    )

        clearTimeout(@_dragTimeout)
        @_dragTimeout = setTimeout(initDrag, config.DRAG_HOLD_DURATION)

    _onMouseMove: (ev) ->
        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

        Element::_onMouseMove.call(@, ev)

    _onMouseUp: (ev) ->
        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

        Element::_onMouseUp.call(@, ev)

    # Key handlers

    _keyTab: (ev) ->
        ev.preventDefault()

        # Indent/Unindent the list item
        if ev.shiftKey
            @parent().unindent()
        else
            @parent().indent()

    _keyReturn: (ev) ->
        ev.preventDefault()

        # If the element only contains whitespace unindent it
        if @content.isWhitespace()
            @parent().unindent()
            return

        # Check if we're allowed to spawn new elements
        unless @can('spawn')
            return

        # Split the element at the text caret
        HtmlSelection.query(@_domElement)
        selection = HtmlSelection.query(@_domElement)
        tip = @content.substring(0, selection.get()[0])
        tail = @content.substring(selection.get()[1])

        # If the user has selected all the list items content then we unindent
        # it. This is the behaviour of a number of mainstream word processors
        # and so we follow their lead here.
        if tip.length() + tail.length() == 0
            @parent().unindent()
            return

        # Update the contents of this element
        @content = tip.trim()
        @updateInnerHTML()

        # Attach the new element
        grandParent = @parent().parent()
        listItem = new moduleClasses.ListItem(
            @root,
            if @attr('class') then {'class': @attr('class')} else {}
        )
        grandParent.attach(
            listItem,
            grandParent.children.indexOf(@parent()) + 1
            )
        listItem.attach(new moduleClasses.ListItemText(@root, tail.trim()))

        # Move any associated list to the new list item
        list = @parent().list()
        if list
            @parent().detach(list)
            listItem.attach(list)

        # Move the focus and text caret based on the split
        if tip.length()
            listItem.listItemText().focus()
            selection = new HtmlSelection(0, 0)
            selection.select(listItem.listItemText().domElement())
        else
            selection = new HtmlSelection(0, tip.length())
            selection.select(@_domElement)

        @taint()

    # Class properties

    @droppers:

        'ListItemText': (element, target, placement) ->
            elementParent = element.parent()
            targetParent = target.parent()

            # Remove the list item from the
            elementParent.remove()
            elementParent.detach(element)

            listItem = new moduleClasses.ListItem(@root, elementParent._attributes)
            listItem.attach(element)

            # If the drop target has children and we're dropping below add it as
            # the first item in the associated list.
            if targetParent.list() and placement[0] == 'below'
                targetParent.list().attach(listItem, 0)
                return

            # Get the position of the target element we're dropping on to
            insertIndex = targetParent.parent().children.indexOf(targetParent)

            # Determine which side of the target to drop the element
            if placement[0] == 'below'
                insertIndex += 1

            # Drop the element into it's new position
            targetParent.parent().attach(listItem, insertIndex)

        'Text': (element, target, placement) ->
            # Text > ListItem
            if element.type() is 'Text'
                targetParent = target.parent()

                # Remove the text element
                element.parent().detach(element)

                # Convert the text item to a list item
                cssClass = element.attr('class')
                listItem = new moduleClasses.ListItem(
                    @root,
                    if cssClass then {'class': cssClass} else {}
                    )
                listItem.attach(new moduleClasses.ListItemText(@root, element.content))

                # If the drop target has children and we're dropping below add
                # it as the first item in the associated list.
                if targetParent.list() and placement[0] == 'below'
                    targetParent.list().attach(listItem, 0)
                    return

                # Get the position of the target element we're dropping on to
                insertIndex = targetParent.parent().children.indexOf(
                    targetParent
                    )

                # Determine which side of the target to drop the element
                if placement[0] == 'below'
                    insertIndex += 1

                # Drop the element into it's new position
                targetParent.parent().attach(listItem, insertIndex)

                # Focus the new text element and set the text caret position
                listItem.listItemText().focus()
                if element._savedSelection
                    element._savedSelection.select(
                        listItem.listItemText().domElement()
                        )

            # ListItem > Text
            else
                # Convert the list item text to a text element
                cssClass = element.attr('class')
                text = new Text(
                    @root,
                    'p',
                    if cssClass then {'class': cssClass} else {},
                    element.content
                )

                # Remove the list item
                element.parent().remove()

                # Insert the text element
                insertIndex = target.parent().children.indexOf(target)

                # Determine which side of the target to drop the element
                if placement[0] == 'below'
                    insertIndex += 1

                # Drop the element into it's new position
                target.parent().attach(text, insertIndex)

                # Focus the new text element and set the text caret position
                text.focus()
                if element._savedSelection
                    element._savedSelection.select(text.domElement())

    @mergers:
         # ListItemText + Text
        'ListItemText': (element, target) ->

            # Remember the target's length so we can offset the text caret to
            # the merge point.
            offset = target.content.length()

            # Add the element's content to the end of the target's
            if element.content.length()
                target.content = target.content.concat(element.content)

            # Update the targets HTML
            if target.isMounted()
                target._domElement.innerHTML = target.content.html()

            # Focus the target and set the text caret position
            target.focus()
            new HtmlSelection(offset, offset).select(target._domElement)

            # Text > ListItemText - just remove the existing text element
            if element.type() == 'Text'
                if element.parent()
                    element.parent().detach(element)

            # ListItemText > Text - cater for removing the list item
            else
                element.parent().remove()

            target.taint()

# Duplicate mergers for other element types
_mergers = ListItemText.mergers
_mergers['Text'] = _mergers['ListItemText']


module.exports = moduleClasses.List
