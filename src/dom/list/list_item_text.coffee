HtmlSelection = require("../../html_selection/html_selection.coffee")
config = require("../config.coffee")
Element = require("../base/element.coffee")
Text = require("../text/text.coffee")

class ListItemText extends Text

    constructor: (@root, content)->
        super(@root, "div", {}, content)

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
        ListItem = require("./list_item.coffee")
        listItem = new ListItem(
            @root,
            if @attr('class') then {'class': @attr('class')} else {}
        )
        grandParent.attach(
            listItem,
            grandParent.children.indexOf(@parent()) + 1
            )
        listItem.attach(new ListItemText(@root, tail.trim()))

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

            ListItem = require("./list_item.coffee")
            listItem = new ListItem(element.root, elementParent._attributes)
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
                ListItem = require("./list_item.coffee")

                targetParent = target.parent()

                # Remove the text element
                element.parent().detach(element)

                # Convert the text item to a list item
                cssClass = element.attr('class')
                listItem = new ListItem(
                    root,
                    if cssClass then {'class': cssClass} else {}
                )
                listItem.attach(new ListItemText(element.root, element.content))

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
                    element.root,
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

module.exports = ListItemText
