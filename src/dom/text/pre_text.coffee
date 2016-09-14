HtmlString = require("../../html_string/html_string.coffee")
HtmlSelection = require("../../html_selection/html_selection.coffee")
Element = require("../base/element.coffee")
Text = require("./text.coffee")
classByTag = require("../class_by_tag.coffee")

class PreText extends Text

    classByTag.associate(@, ['pre'])

    # An editable body of preserved text (e.g <pre>).

    constructor: (@root, tagName, attributes, content) ->
        # The content of the text element
        if content instanceof HtmlString
            @content = content
        else
            @content = new HtmlString(content, true)

        Element.call(@, @root, tagName, attributes)

    # Read-only properties

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'PreText'

    # Methods

    blur: () ->
        if @isMounted()
            @_domElement.innerHTML = @content.html()

        super()

    html: (indent='') ->
        # Return a HTML string for the node

        # For text elements with optimized output we use a cache to improve
        # performance for repeated calls.
        if not @_lastCached or @_lastCached < @_modified

            # Optimize the content for output
            content = @content.copy()
            content.optimize()

            @_lastCached = Date.now()
            @_cached = content.html()

        return "#{ indent }<#{ @_tagName }#{ @_attributesToString() }>" +
            "#{ @_cached }</#{ @_tagName }>"

    updateInnerHTML: () ->
        # Update the inner HTML of the DOM element with the elements content
        html = @content.html()
        @_domElement.innerHTML = html
        @_ensureEndZWS()
        HtmlSelection.prepareElement(@_domElement)
        @_flagIfEmpty()

    # Event handlers

    _keyBack: (ev) ->

        # If the selection is within the known content behave as normal...
        selection = HtmlSelection.query(@_domElement)
        if selection.get()[0] <= @content.length()
            return super(ev)

        # ...if not set the selection to the end of the string (not the
        # contents).
        selection.set(@content.length(), @content.length())
        selection.select(@_domElement)

    # Key events

    _keyReturn: (ev) ->
        ev.preventDefault()

        # Insert a `\n` character at the current position
        selection = HtmlSelection.query(@_domElement)
        cursor = selection.get()[0] + 1

        # Depending on the selection determine how best to insert the content
        if selection.get()[0] == 0 and selection.isCollapsed()
            @content = new HtmlString('\n', true).concat(@content)

        else if @_atEnd(selection) and selection.isCollapsed()
            @content = @content.concat(new HtmlString('\n', true))

        else if selection.get()[0] == 0 and
                    selection.get()[1] == @content.length()
            @content = new HtmlString('\n', true)
            cursor = 0

        else
            tip = @content.substring(0, selection.get()[0])
            tail = @content.substring(selection.get()[1])
            @content = tip.concat(new HtmlString('\n', true), tail)

        @updateInnerHTML()

        # Restore the selection
        selection.set(cursor, cursor)
        selection.select(@_domElement)

        @taint()

    # Private methods

    _syncContent: (ev) ->
        @_ensureEndZWS()

        # Keep the content in sync with the HTML and check if it's been modified
        # by the key events.
        snapshot = @content.html()
        @content = new HtmlString(
            @_domElement.innerHTML.replace(/\u200B$/g, ''),
            @content.preserveWhitespace()
        )

        # If the snap-shot has changed mark the node as modified
        newSnapshot = @content.html()
        if snapshot != newSnapshot
            @taint()

        @_flagIfEmpty()

    _ensureEndZWS: () ->
        # HACK: Append an zero-width-space (ZWS) character to the DOM elements
        # inner HTML to ensure the caret position moves when a newline is added
        # to the end of the content (e.g if the user hits the return key - see
        # issue #54).

        # Check we need to add the ZWS
        if not @_domElement.lastChild
            return

        html = @_domElement.innerHTML
        if html[html.length - 1] == '\u200B'
            if html.indexOf('\u200B') < html.length - 1
                return

        # Add the ZWS and restore the state (only if the state isn't already
        # set).
        _addZWS = () =>
            # Clear any erroneous ZWS characters
            if html.indexOf('\u200B') > -1
                @_domElement.innerHTML = html.replace(/\u200B/g, '')

            # Add the ZWS character as a text node to the end of the element's
            # HTML.
            @_domElement.lastChild.textContent += '\u200B'

        # Check to see if the state of the element has already been captured or
        # if we need to capture it before updating the the contents.
        if this._savedSelection
            _addZWS()

        else
            @storeState()
            _addZWS()
            @restoreState()

    # Class properties

    @droppers:
        'PreText': Element._dropVert
        'Static': Element._dropVert
        'Text': Element._dropVert

    @mergers: {}

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type
        return new @(
            root,
            domElement.tagName,
            @getDOMElementAttributes(domElement),
            domElement.innerHTML
        )

module.exports = PreText
