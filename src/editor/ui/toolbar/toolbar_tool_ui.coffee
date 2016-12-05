Anchored = require("../anchored.coffee")
i18n = require("../../../dom/_/i18n.coffee")

class ToolbarToolUI extends Anchored

    # A tool that can be selected in the toolbox.

    constructor: (@editor, tool) ->
        super()

        # The tool associated with this UI tool
        @tool = tool

        # Flag indicating if the mouse button is down whilst the cursor is over
        # (and remains over) the tool.
        @_mouseDown = false

        # Flag indicating if the tools is disabled
        @_disabled = false

    # Methods

    apply: (element, selection) ->
        # Apply the tool UIs associated tool
        unless @tool.canApply(element, selection)
            return

        detail = {
            'element': element,
            'selection': selection
            }

        callback = (applied) =>
            if applied
                @dispatchEvent(@createEvent('applied', detail))

        if @dispatchEvent(@createEvent('apply', detail))
            @tool.apply(element, selection, callback)

    disabled: (disabledState) ->
        # Get/Set the disabled state of the tool

        # Return the current state if `disabledState` hasn't been provided
        if disabledState == undefined
            return @_disabled

        # Set the state
        if @_disabled == disabledState
            return

        # Set the disabled state
        @_disabled = disabledState

        if disabledState
            # Disable the tool
            @_mouseDown = false
            @addCSSClass('ct-tool--disabled')
            @removeCSSClass('ct-tool--applied')

        else
            # Enable the tool
            @removeCSSClass('ct-tool--disabled')

    mount: (domParent, before=null) ->
        # Mount the component to the DOM

        @_domElement = @constructor.createDiv([
            'ct-tool',
            "ct-tool--#{ @tool.icon }"
            ])

        # Add the tooltip
        @_domElement.setAttribute('data-tooltip', i18n(@tool.label))
        @_domElement.innerHTML = @tool.label

        super(domParent, before)

    update: (element, selection) ->
        # Update the state of the tool based on the current element and
        # selection.

        # Most elements are automatically disabled if there is no element
        # however some tools such as redo/undo don't require an element to be
        # applied.
        if @tool.requiresElement
            # If there's no element selected then the tool is disabled
            if not (element and element.isMounted())
                @disabled(true)
                return

        # Check if the tool can be applied
        if @tool.canApply(element, selection)
            @disabled(false)
        else
            @disabled(true)
            return

        # Check of the tool is already being applied
        if @tool.isApplied(element, selection)
            @addCSSClass('ct-tool--applied')
        else
            @removeCSSClass('ct-tool--applied')

    # Private methods

    _addDOMEventListeners: () =>
        # Add all event bindings for the DOM element in this method
        @_domElement.addEventListener('mousedown', @_onMouseDown)
        @_domElement.addEventListener('mouseleave', @_onMouseLeave)
        @_domElement.addEventListener('mouseup', @_onMouseUp)

    # It's important to note that the click event for tools is managed in order
    # to prevent focus being lost from an element because of a tool being
    # clicked. Native 'mousedown' events triggered have their defaults
    # prevented.

    _onMouseDown: (ev) =>
        # Flag that the mouse has been clicked down over the tool
        ev.preventDefault()

        # If the tool is disabled ignore this event
        if @disabled()
            return

        @_mouseDown = true
        @addCSSClass('ct-tool--down')

    _onMouseLeave: (ev) =>
        # Cursor has left the tool so remove flag indicating the mouse is down
        # over the tool.
        @_mouseDown = false
        @removeCSSClass('ct-tool--down')

    _onMouseUp: (ev) =>
        # If a click event has occured exectute the tool
        if @_mouseDown
            element = @editor.root.focused()

            # Most elements are automatically disabled if there is no element
            # however some tools such as redo/undo don't require an element to
            # be applied.
            if @tool.requiresElement
                unless element and element.isMounted()
                    return

            selection = null
            if element and element.selection
                selection = element.selection()

            @apply(element, selection)

        # Reset the mouse down flag
        @_mouseDown = false
        @removeCSSClass('ct-tool--down')

module.exports = ToolbarToolUI
