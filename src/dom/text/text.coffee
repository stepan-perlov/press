HtmlString = require("../../html_string/html_string")
HtmlSelection = require("../../html_selection/html_selection")
Element = require("../base/element")
classByTag = require("../class_by_tag")
config = require("../config")


class Text extends Element

    classByTag.associate(@, [
        'address'
        'blockquote'
        'h1'
        'h2'
        'h3'
        'h4'
        'h5'
        'h6'
        'p'
    ])

    # An editable body of text (e.g <address>, <blockquote>, <h1-h6>, <p>).

    constructor: (@root, tagName, attributes, content)->
        super(@root, tagName, attributes)

        # The content of the text element
        if content instanceof HtmlString
            @content = content
        else
            # Strings are trimmed initially to prevent selection issues with
            # whitespaces inside of starting or ending tags
            # (e.g starting <p><a> abc</a>, or ending <a>abc </a></p>).
            @content = new HtmlString(content).trim()

    # Read-only properties
    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'Text'

    # Methods

    blur: ->
        # Remove editing focus from this element

        # Last chance - check for changes in the content not captured before
        # this point.
        if @isMounted()
            @_syncContent()

        if @content.isWhitespace() and @can('remove')
            # Detatch element from parent if empty
            if @parent()
                @parent().detach(this)

        else if @isMounted()
            # Blur the DOM element
            try
                @_domElement.blur()
            catch error
                # HACK: Do nothing if this fails, internet explorer doesn't
                # allow blur to be triggered against the contentediable element
                # programatically and will trigger the following error:
                #
                # `Unexpected call to method or property access.`

            # Stop the element from being editable
            @_domElement.removeAttribute('contenteditable')

        super()

    createDraggingDOMElement: ->
        # Create a DOM element that visually aids the user in dragging the
        # element to a new location in the editiable tree structure.
        unless @isMounted()
            return

        helper = super()

        # Use the body of the node to create the helper but limit the text to
        # something sensible.
        text = HtmlString.encode(@_domElement.textContent)
        if text.length > config.HELPER_CHAR_LIMIT
            text = text.substr(0, config.HELPER_CHAR_LIMIT)

        helper.innerHTML = text

        return helper

    drag: (x, y)->
        # Drag the element to a new position
        @storeState()

        # Prevent content editing whilst the element is being dragged
        @_domElement.removeAttribute('contenteditable')
        super(x, y)

    drop: (element, placement)->
        # Drop the element into a new position in the editable structure
        super(element, placement)
        @restoreState()

    focus: (supressDOMFocus)->
        # Focus this element for editing

        # Make the element editable if mounted
        if @isMounted()
            @_domElement.setAttribute('contenteditable', '')

        super(supressDOMFocus)

    html: (indent='')->
        # Return a HTML string for the node

        # For text elements with optimized output we use a cache to improve
        # performance for repeated calls.
        if not @_lastCached or @_lastCached < @_modified

            # Optimize the content for output
            content = @content.copy().trim()
            content.optimize()

            @_lastCached = Date.now()
            @_cached = content.html()

        # If this is a fixed element only return the inner HTML
        if @isFixed()
            return @_cached
        else
            return "#{ indent }<#{ @_tagName }#{ @_attributesToString() }>\n" +
                "#{ indent }#{ config.INDENT }#{ @_cached }\n" +
                "#{ indent }</#{ @_tagName }>"

    mount: ->
        # Mount the element on to the DOM

        # Create the DOM element to mount
        @_domElement = document.createElement(@_tagName)

        # Set the attributes
        for name, value of @_attributes
            @_domElement.setAttribute(name, value)

        # Set the content in the document
        @updateInnerHTML()

        super()

    restoreState: ->
        # Restore the text elements state after storeState has been called
        unless @_savedSelection
            return

        unless @isMounted() and @isFocused()
            @_savedSelection = undefined
            return

        @_domElement.setAttribute('contenteditable', '')
        @_addCSSClass('ce-element--focused')

        # If we're restoring the selection state then we need to make sure the
        # element has focus.
        if document.activeElement != @domElement()
            @domElement().focus()

        @_savedSelection.select(@_domElement)
        @_savedSelection = undefined

    selection: (selection)->
        # Get/Set the content selection for the element
        if selection is undefined
            if @isMounted()
                return HtmlSelection.query(@_domElement)
            else
                return new HtmlSelection(0, 0)

        selection.select(@_domElement)

    storeState: ->
        # Save the state of the text element so that it can be restored after
        # being unmounted and re-mounted.
        unless @isMounted() and @isFocused()
            return

        @_savedSelection = HtmlSelection.query(@_domElement)

    unmount: ->
        # Unmount the element on from the DOM

        # Remove the contenteditable attribute
        @_domElement.removeAttribute('contenteditable')

        super()

    updateInnerHTML: ->
        # Update the inner HTML of the DOM element with the elements content
        @_domElement.innerHTML = @content.html()
        HtmlSelection.prepareElement(@_domElement)
        @_flagIfEmpty()

    # Event handlers

    _onKeyDown: (ev)->
        # Handle special key events
        switch ev.keyCode

            # Navigation
            when 40 then @_keyDown(ev)
            when 37 then @_keyLeft(ev)
            when 39 then @_keyRight(ev)
            when 38 then @_keyUp(ev)
            when 9 then @_keyTab(ev)

            # Merging
            when 8 then @_keyBack(ev)
            when 46 then @_keyDelete(ev)

            # Splitting
            when 13 then @_keyReturn(ev)

    _onKeyUp: (ev)->
        super(ev)
        @_syncContent()

    _onMouseDown: (ev)->
        # Give the element focus
        super(ev)

        # If the user holds the mouse down for an extended period then start
        # dragging the element.
        clearTimeout(@_dragTimeout)
        @_dragTimeout = setTimeout(
            () =>
                @drag(ev.pageX, ev.pageY)
            config.DRAG_HOLD_DURATION
            )

        # HACK: If the content of the element is empty and it already has focus
        # then supress the event to stop odd behaviour in FireFox. See issue:
        # https://github.com/GetmeUK/ContentTools/issues/118
        #
        # Anthony Blackshaw <ant@getme.co.uk>, 2016-01-30
        if @content.length() == 0 and @root.focused() is this
            ev.preventDefault()
            if document.activeElement != this._domElement
                this._domElement.focus()
            new HtmlSelection(0, 0).select(this._domElement)

    _onMouseMove: (ev)->
        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

        super(ev)

    _onMouseOut: (ev)->
        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

        super(ev)

    _onMouseUp: (ev)->
        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

        super(ev)

    # Key handlers

    _keyBack: (ev)->
        selection = HtmlSelection.query(@_domElement)
        unless selection.get()[0] == 0 and selection.isCollapsed()
            return

        ev.preventDefault()

        # If we're at the start of the element attempt to find the previous text
        # element and merge with it.
        previous = @previousContent()

        # We need to sync the content as this event can occur without a
        # corresponding key up event (e.g the back key was held down).
        @_syncContent()

        if previous
            previous.merge(this)

    _keyDelete: (ev)->
        selection = HtmlSelection.query(@_domElement)
        unless @_atEnd(selection)and selection.isCollapsed()
            return

        ev.preventDefault()

        # If we're at the end of the element attempt to find the next text
        # element and merge with it.
        next = @nextContent()
        if next
            @merge(next)

    _keyDown: (ev)->
        @_keyRight(ev)

    _keyLeft: (ev)->
        selection = HtmlSelection.query(@_domElement)
        unless selection.get()[0] == 0 and selection.isCollapsed()
            return

        # If we're at the start of the element and the selection is collapsed we
        # should navigate to the previous text node.
        ev.preventDefault()

        # Attempt to find and select the previous content element
        previous = @previousContent()
        if previous
            previous.focus()
            selection = new HtmlSelection(
                previous.content.length(),
                previous.content.length()
                )
            selection.select(previous.domElement())
        else
            # If no element was found this must be the last content node found
            # so trigger an event for external code to manage a region switch.
            @root.trigger(
                'previous-region',
                @closest (node) ->
                    node.type() is 'Fixture' or node.type() is 'Region'
            )

    _keyReturn: (ev)->
        ev.preventDefault()

        # If the element only contains whitespace and we're not being asked to
        # insert a line break.
        if @content.isWhitespace() and
                not ev.shiftKey ^ config.PREFER_LINE_BREAKS
            return

        # Split the element at the text caret
        selection = HtmlSelection.query(@_domElement)
        tip = @content.substring(0, selection.get()[0])
        tail = @content.substring(selection.get()[1])

        # If the shift key is held down or if the preference is to insert
        # line-breaks over new paragraphs then insert a line-break instead of
        # creating a new paragraph.
        if ev.shiftKey ^ config.PREFER_LINE_BREAKS
            insertAt = selection.get()[0]

            # Check if this is the last character in the row
            lineBreakStr = '<br>'
            if @content.length() == insertAt
                # HACK: If this is the last character then we'll need to insert
                # two `<br>` if the current last character is not a `<br>`. This
                # appears to be the only way to get the browsers to consistently
                # provide the expected behaviour (see issue #101 on
                # ContentTools).
                if @content.length() == 0 or
                        not @content.characters[insertAt - 1].isTag('br')
                    lineBreakStr = '<br><br>'

            # Rejoin the content with a line-break
            @content = @content.insert(
                insertAt,
                new HtmlString(lineBreakStr, true),
                true
                )
            @updateInnerHTML()

            # Reset the caret's position
            insertAt += 1
            selection = new HtmlSelection(insertAt, insertAt)
            selection.select(@domElement())

            @taint()

            return

        # Check if we're allowed to spawn new elements
        unless @can('spawn')
            return

        # Update the contents of this element
        @content = tip.trim()
        @updateInnerHTML()

        # Attach the new element
        element = new @constructor(@root, 'p', {}, tail.trim())
        @parent().attach(element, @parent().children.indexOf(this) + 1)

        # Move the focus and text caret based on the split
        if tip.length()
            element.focus()
            selection = new HtmlSelection(0, 0)
            selection.select(element.domElement())
        else
            selection = new HtmlSelection(0, tip.length())
            selection.select(@_domElement)

        @taint()

    _keyRight: (ev)->
        selection = HtmlSelection.query(@_domElement)
        unless @_atEnd(selection) and selection.isCollapsed()
            return

        # If we're at the end of the element and the selection is collapsed we
        # should navigate to the next text node.
        ev.preventDefault()

        # Attempt to find and select the next text element
        next = @nextContent()
        if next
            next.focus()
            selection = new HtmlSelection(0, 0)
            selection.select(next.domElement())
        else
            # If no element was found this must be the last content node found
            # so trigger an event for external code to manage a region switch.
            @root.trigger(
                'next-region',
                @closest (node) ->
                    node.type() is 'Fixture' or node.type() is 'Region'
                )

    _keyTab: (ev)->
        ev.preventDefault()

        # If this is a fixture element then we trigger a switch region event to
        # allow external code to manage.
        if @isFixed()

            # If the shift key is held down then we reverse the switch to the
            # `previous-region` event.
            if ev.shiftKey
                @root.trigger(
                    'previous-region',
                    @closest (node) ->
                        node.type() is 'Fixture' or node.type() is 'Region'
                )

            else
                @root.trigger(
                    'next-region',
                    @closest (node) ->
                        node.type() is 'Fixture' or node.type() is 'Region'
                )

    _keyUp: (ev)->
        @_keyLeft(ev)

    # Private methods

    _atEnd: (selection)->
        # Determine if the cursor/caret starts at the end of the content
        return selection.get()[0] >= @content.length()

    _flagIfEmpty: ->
        # Flag the element as empty if there's no content
        if @content.length() == 0
            @_addCSSClass('ce-element--empty')
        else
            @_removeCSSClass('ce-element--empty')

    _syncContent: (ev)->
        # Keep the content in sync with the HTML and check if it's been modified
        # by the key events.
        snapshot = @content.html()
        @content = new HtmlString(
            @_domElement.innerHTML,
            @content.preserveWhitespace()
        )

        # If the snap-shot has changed mark the node as modified
        newSnapshot = @content.html()
        if snapshot != newSnapshot
            @taint()

        @_flagIfEmpty()

    # Class properties

    @droppers:
        'Static': Element._dropVert
        'Text': Element._dropVert

    @mergers:

        'Text': (element, target)->

            # Remember the target's length so we can offset the text caret to
            # the merge point.
            offset = target.content.length()

            # Add the element's content to the end of the target's
            if element.content.length()
                target.content = target.content.concat(element.content)

            # Update the targets HTML
            if target.isMounted()
                target.updateInnerHTML()

            # Focus the target and set the text caret position
            target.focus()
            new HtmlSelection(offset, offset).select(target._domElement)

            # Remove the element
            if element.parent()
                element.parent().detach(element)

            # Taint both elements
            target.taint()

    # Class methods

    @fromDOMElement: (root, domElement)->
        # Convert an element (DOM) to an element of this type
        return new @(
            root,
            domElement.tagName,
            @getDOMElementAttributes(domElement),
            domElement.innerHTML.replace(/^\s+|\s+$/g, '')
        )

module.exports = Text
