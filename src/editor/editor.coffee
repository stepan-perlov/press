HTMLSelection = require("../html_selection/html_selection")
HTMLString = require("../html_string/html_string")

addCSSClass = require("../dom/_/add_css_class")
removeCSSClass = require("../dom/_/remove_css_class")

Root = require("../dom/base/root")
Region = require("../dom/region/region")
Text = require("../dom/text/text")
ListItem = require("../dom/list/list_item")
ListItemText = require("../dom/list/list_item_text")

config = require("./config")
View = require("./ui/view")
History = require("./behaviour/history")

ToolbarUI = require("./ui/toolbar/toolbar_ui")

class Editor extends View
    #
    # Getters
    #
    ctrlDown: ->
        @_ctrlDown

    shiftDown: () ->
        return @_shiftDown

    toolbox: () ->
        # Return the toolbox component for the editor
        return @_toolbox

    domRegions: () ->
        # Return a list of DOM nodes that are assigned as be editable regions
        @_domRegions

    regions: () ->
        # Return a list of editable regions on the page
        return @_regions

    orderedRegions: () ->
        # Return a list of regions in the given order
        return (@_regions[name] for name in @_orderedRegions)

    #
    # Constructor
    #
    constructor: (
        domElement,
        regionsQuery,
        regionNameAttribute = "data-region",
        mount = true
    )->
        super()

        @_domElement = domElement
        @_regionsQuery = regionsQuery
        @_domRegions = document.querySelectorAll(regionsQuery)
        @_regionNameAttribute = regionNameAttribute

        @root = new Root()

        @history = null

        # A map of editable regions
        @_regions = {}
        # A list of the mapped regions used to determine their order
        @_orderedRegions = []

        # The last modified dates for regions
        @_regionsLastModified = {}

        @mount() if mount
    #
    # Methods
    #
    mount: ->
        @addCSSClass("press-editor")

        @_initEventsHandlers()

        document.addEventListener('keydown', @_handleHighlightOn)
        document.addEventListener('keyup', @_handleHighlightOff)

        @root.bind('detach', @_handleDetach)

        # Monitor paste events so that we can pre-parse the content the user
        # wants to paste into the region.
        @root.bind('paste', @_handleClipboardPaste)

        # Manage the transition between regions
        @root.bind('next-region', @_handleNextRegionTransition)
        @root.bind('previous-region', @_handlePreviousRegionTransition)


        @_initRegions()

        @history = new History(@, @_regions)
        @history.watch()

        @_toolbox = new ToolbarUI(@, config.DEFAULT_TOOLS)
        @attach(@_toolbox)
        @_toolbox.show()
    unmount: ->
        @removeCSSClass("press-editor")

        document.removeEventListener('keydown', @_handleHighlightOn)
        document.removeEventListener('keyup', @_handleHighlightOff)

        @history.stopWatching()
        @history = null

    highlightRegions: (highlight) ->
        # Highlight (or stop highlighting) editiable regions within the page
        for domRegion in @_domRegions
            if highlight
                addCSSClass(domRegion, 'ct--highlight')
            else
                removeCSSClass(domRegion, 'ct--highlight')

    paste: (element, clipboardData) ->
        # Paste content into the given element
        content = clipboardData

        # Extract the content of the clipboard
        # content = clipboardData.getData('text/plain')

        # Convert the content into a series of lines to be inserted
        lines = content.split('\n')

        # Filter out any blank (whitespace only) lines
        lines = lines.filter (line) ->
            return line.trim() != ''

        # Check there's something to paste
        if not lines
            return

        # Determine whether the new content should be pasted into the existing
        # element or should spawn new elements for each line of content.
        encodeHTML = HTMLString.encode
        spawn = true
        type = element.type()

        # Are their multiple lines to add?
        if lines.length == 1
            spawn = false

        # Is this a pre-text element which supports multiline content?
        if type == 'PreText'
            spawn = false

        # Does the element itself allow content to be spawned from it?
        if not element.can('spawn')
            spawn = false

        if spawn
            # Paste the content as multiple elements

            # Find the insertion point in the document
            if type == 'ListItemText'
                # If the element is a ListItem then we want to insert the lines
                # as siblings.
                insertNode = element.parent()
                insertIn = element.parent().parent()
                insertAt = insertIn.children.indexOf(insertNode) + 1
            else
                # For any other element type we want to insert the lines as
                # paragraphs.
                insertNode = element
                if insertNode.parent().type() != 'Region'
                    insertNode = element.closest (node) ->
                        return node.parent().type() is 'Region'

                insertIn = insertNode.parent()
                insertAt = insertIn.children.indexOf(insertNode) + 1

            # Insert each line as a paragraph
            for line, i in lines
                line = encodeHTML(line)
                if type == 'ListItemText'
                    item = new ListItem(@root)
                    itemText = new ListItemText(@root, line)
                    item.attach(itemText)
                    lastItem = itemText
                else
                    item = new Text(@root, 'p', {}, line)
                    lastItem = item

                insertIn.attach(item, insertAt + i)

            # Give focus to the last line/paragraph added and position the
            # cursor at the end of it.
            lineLength = lastItem.content.length()
            lastItem.focus()
            lastItem.selection(new HTMLSelection(lineLength, lineLength))

        else
            # Paste the content within the existing element

            # Convert the content to a HTMLString
            content = encodeHTML(content)
            content = new HTMLString(content, type is 'PreText')

            # Insert the content into the element's existing content
            selection = element.selection()
            cursor = selection.get()[0] + content.length()
            tip = element.content.substring(0, selection.get()[0])
            tail = element.content.substring(selection.get()[1])

            # Format the string using tags for the first character it is
            # replacing (if any).
            replaced = element.content.substring(
                selection.get()[0],
                selection.get()[1]
                )
            if replaced.length()
                character = replaced.characters[0]
                tags = character.tags()

                if character.isTag()
                    tags.shift()

                if tags.length >= 1
                    content = content.format(0, content.length(), tags...)

            element.content = tip.concat(content)
            element.content = element.content.concat(tail, false)
            element.updateInnerHTML()

            # Mark the element as tainted
            element.taint()

            # Restore the selection
            selection.set(cursor, cursor)
            element.selection(selection)

    revert: () ->
        # Revert the page to it's previous state before we started editing
        # the page.
        if not @dispatchEvent(@createEvent('revert'))
            return

        # Check if there are any changes, and if there are make the user confirm
        # they want to lose them.
        confirmMessage = ContentEdit._(
            'Your changes have not been saved, do you really want to lose them?'
            )
        if @root.lastModified() > @_rootLastModified and
                not window.confirm(confirmMessage)
            return false

        # Revert the page to it's initial state
        @revertToSnapshot(@history.goTo(0), false)

        return true

    revertToSnapshot: (snapshot, restoreEditable=true) ->
        # Revert the page to the specified snapshot (the snapshot should be a
        # map of regions and the associated HTML).

        for name, region of @_regions
            # Apply the changes made to the DOM (affectively reseting the DOM to
            # a non-editable state).

            # Unmount all children
            for child in region.children
                child.unmount()

            region.domElement().innerHTML = snapshot.regions[name]

        # Check to see if we need to restore the regions to an editable state
        if restoreEditable
            # Unset any focused element against root
            if @root.focused()
                @root.focused().blur()

            # Reset the regions map
            @_regions = {}

            @syncRegions()

            # Update history with the new regions
            @history.replaceRegions(@_regions)

            # Restore the selection for the snapshot
            @history.restoreSelection(snapshot)

            # Update the inspector tags
            #@_inspector.updateTags()

    syncRegions: (regionQuery) ->
        # Sync the editor with the page in order to map out the regions/fixtures
        # that can be edited.

        # If a region query has been provided then set it

        # Find the DOM elements that will be managed as regions/fixtures
        @_domRegions = document.querySelectorAll(@_regionsQuery)
        @_initRegions()

    #
    # private methods
    #
    #
    _allowEmptyRegions: (callback) ->
        # Execute a function while allowing empty regions (e.g disabling the
        # default `_preventEmptyRegions` behaviour).
        @_emptyRegionsAllowed = true
        callback()
        @_emptyRegionsAllowed = false

    _preventEmptyRegions: () ->
        # Ensure no region is empty by inserting a placeholder <p> tag if
        # required.
        if @_emptyRegionsAllowed
            return

        # Check for any region that is now empty
        for name, region of @_regions
            lastModified = region.lastModified()

            # We have to check for elements that can receive focus as static
            # elements alone don't allow new content to be added to a region.
            hasEditableChildren = false
            for child in region.children
                if child.type() != 'Static'
                    hasEditableChildren = true
                    break

            if hasEditableChildren
                continue

            # Insert a placeholder text element to prevent the region from
            # becoming empty.
            placeholder = new Text(@root, 'p', {}, '')
            region.attach(placeholder)

            # HACK: This action will mark the region as modified which it
            # technically isn't and so we commit the change to nullify this.
            region._modified = lastModified

    # Initialize regions
    #
    _initRegions: ->
        # Initialize DOM regions within the page

        found = {}
        for domRegion, i in @_domRegions

            # Find a name for the region
            name = domRegion.getAttribute(@_regionNameAttribute)

            # If we can't find a name assign the region a name based on its
            # position on the page.
            if not name
                name = i

            # Remember that we added a region/fixture with this name, those that
            # aren't found are removed.
            found[name] = true

            # Check if the region/fixture is already initialized, in which case
            # we're done.
            if @_regions[name] and @_regions[name].domElement() == domRegion
                continue

            # Initialize the new region/fixture
            @_regions[name] = new Region(@root, domRegion)

            # Update the order
            @_orderedRegions.push(name)

            # Store the date at which the region was last modified so we can
            # check for changes on save.
            @_regionsLastModified[name] = @_regions[name].lastModified()

        # Remove any regions no longer part of the page
        for name, region of @_regions

            # If the region exists
            if found[name]
                continue

            # Remove the region
            delete @_regions[name]
            delete @_regionsLastModified[name]
            index = @_orderedRegions.indexOf(name)
            if index > -1
                @_orderedRegions.splice(index, 1)
    #
    # Initialize events handlers
    #
    _initEventsHandlers: ->
        # keyboard events
        @_handleHighlightOn = (ev) =>
            if ev.keyCode in [17, 224, 91, 93] # Ctrl/Cmd
                @_ctrlDown = true
                return

            if ev.keyCode is 16 # Shift
                # Check for repeating key in which case we don't want to create
                # additional timeouts.
                if @_highlightTimeout
                    return

                @_shiftDown = true
                @_highlightTimeout = setTimeout(
                    => @highlightRegions(true),
                    config.HIGHLIGHT_HOLD_DURATION
                )

        @_handleHighlightOff = (ev) =>
            # Ignore repeated key press events
            if ev.keyCode in [17, 224] # Ctrl/Cmd
                @_ctrlDown = false
                return

            if ev.keyCode is 16 # Shift
                @_shiftDown = false
                if @_highlightTimeout
                    clearTimeout(@_highlightTimeout)
                    @_highlightTimeout = null
                @highlightRegions(false)

        @_handleDetach = (element) =>
            @_preventEmptyRegions()

        # root events
        @_handleClipboardPaste = (element, ev) =>
            # Get the clipboardData
            clipboardData = null

            # Non-IE browsers
            if ev.clipboardData
              clipboardData = ev.clipboardData.getData('text/plain')

            # IE browsers
            if window.clipboardData
              clipboardData = window.clipboardData.getData('TEXT')

            @paste(element, clipboardData)

        @_handleNextRegionTransition = (region) =>
            # Is there a next region?
            regions = @orderedRegions()
            index = regions.indexOf(region)
            if index >= (regions.length - 1)
                return

            # Move to the next region
            region = regions[index + 1]

            # Is there a content element to move to?
            element = null
            for child in region.descendants()
                if child.content != undefined
                    element = child
                    break

            # If there is a content child move the selection to it else check
            # the next region.
            if element
                element.focus()
                element.selection(new HTMLSelection(0, 0))
                return

            @root.trigger('next-region', region)

        @_handlePreviousRegionTransition = (region) =>
            # Is there a previous region?
            regions = @orderedRegions()
            index = regions.indexOf(region)
            if index <= 0
                return

            # Move to the previous region
            region = regions[index - 1]

            # Is there a content element to move to?
            element = null
            descendants = region.descendants()
            descendants.reverse()
            for child in descendants
                if child.content != undefined
                    element = child
                    break

            # If there is a content child move the selection to it else check
            # the next region.
            if element
                length = element.content.length()
                element.focus()
                element.selection(new HTMLSelection(length, length))
                return

module.exports = Editor
