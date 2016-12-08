Node = require("./node")
config = require("../config")
attributesToString = require("../_/attributes_to_string")
addCSSClass = require("../_/add_css_class")
removeCSSClass = require("../_/remove_css_class")
i18n = require("../_/i18n")

class Element extends Node

    # The `Element` class is used to implement nodes that appear as HTML
    # elements.

    constructor: (@root, tagName, attributes)->
        super(@root)

        # The tag name (e.g h1 or p)
        @_tagName = tagName.toLowerCase()

        # The attributes (e.g <p id="foo" class="bar">)
        @_attributes = if attributes then attributes else {}

        # The DOM element associated with the element
        @_domElement = null

        # A dictionary of behaviour flags which can be configured to determine
        # what behaviour an element allows.
        @_behaviours = {
            drag: true,   # The element can be dragged
            drop: true,   # The element can be dropped on to
            merge: true,  # The element can be merged with another
            remove: true, # The element can be removed
            resize: true, # The element can be resized
            spawn: true   # The element can spawn new elements
        }

    # Read-only properties

    attributes: ->
        # Return an copy of the elements attributes
        attributes = {}
        for name, value of @_attributes
            attributes[name] = value
        return attributes

    domElement: ->
        # Return the DOM element associated with the element
        return @_domElement

    isFixed: ->
        # Return true if the element is parented by a fixture
        return @parent() and @parent().type() == 'Fixture'

    isFocused: ->
        # Return true if the element currently has focus
        return @root.focused() == this

    isMounted: ->
        # Return true if the node is mounted in the DOM
        return @_domElement != null

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'Element'

    # Methods

    addCSSClass: (className)->
        # Add a CSS class to the element

        # Check if we need to add the class
        modified = false
        unless @hasCSSClass(className)
            modified = true
            if @attr('class')
                @attr('class', "#{ @attr('class') } #{ className }")
            else
                @attr('class', className)

        # Add the CSS class to the DOM element
        @_addCSSClass(className)

        # Mark the element as modified
        if modified
            @taint()

    attr: (name, value)->
        # Get/Set the value of an attribute for the element, the attribute is
        # only set if a value is specified.
        name = name.toLowerCase()

        # Get...
        if value == undefined
            return @_attributes[name]

        # ...or Set the attribute
        @_attributes[name] = value

        # Set the attribute against the DOM element if mounted and we're not
        # setting `class`. CSS classes should always be set using the
        # `addCSSClass` method which sets the class against the mounted
        # DOM element whilst maintaining the classes applied for editing.
        if @isMounted() and name.toLowerCase() != 'class'
            @_domElement.setAttribute(name, value)

        # Mark as modified
        @taint()

    blur: ->
        # Remove focus from the element
        if @isFocused()
            @_removeCSSClass('ce-element--focused')
            @root._focused = null
            @root.trigger('blur', this)

    can: (behaviour, allowed)->
        # Get/Set the behaviour allowed for an element

        # Get...
        if allowed == undefined
            return (not @isFixed()) and @_behaviours[behaviour]

        # ...or Set the permission
        @_behaviours[behaviour] = allowed

    createDraggingDOMElement: ->
        # Create a DOM element that visually aids the user in dragging the
        # element to a new location in the editiable tree structure.
        unless @isMounted()
            return

        helper = document.createElement('div')
        helper.setAttribute(
            'class',
            "ce-drag-helper ce-drag-helper--type-#{ @cssType() }"
            )
        helper.setAttribute('data-ce-type', i18n(@type()));

        return helper

    drag: (x, y)->
        # Drag the element to a new position
        unless @isMounted() and @can('drag')
            return

        @root.startDragging(this, x, y)
        @root.trigger('drag', this)

    drop: (element, placement)->
        # Drop the element into a new position in the editable structure, if no
        # element is provided, or a method to manage the drop isn't defined the
        # drop is cancelled.
        unless @can('drop')
            return

        if element
            # Remove the drop class from the element
            element._removeCSSClass('ce-element--drop')
            element._removeCSSClass("ce-element--drop-#{ placement[0] }")
            element._removeCSSClass("ce-element--drop-#{ placement[1] }")

            # Determine if either elements class supports the drop
            if @constructor.droppers[element.type()]
                @constructor.droppers[element.type()](
                    this,
                    element,
                    placement
                    )
                @root.trigger('drop', this, element, placement)
                return

            else if element.constructor.droppers[@type()]
                element.constructor.droppers[@type()](
                    this,
                    element,
                    placement
                    )
                @root.trigger('drop', this, element, placement)
                return

        # The drop was unsuccessful so trigger drop event without target or
        # placement.
        @root.trigger('drop', this, null, null)

    focus: (supressDOMFocus)->
        # Focus the element

        # Does this element already have focus
        if @isFocused()
            return

        # Is there an existing element with focus? If so we need to blur it
        if @root.focused()
            @root.focused().blur()

        # Set this element as focused
        @_addCSSClass('ce-element--focused')
        @root._focused = this

        # Focus on the element
        if @isMounted() and not supressDOMFocus
            @domElement().focus()

        @root.trigger('focus', this)

    hasCSSClass: (className)->
        # Return true if the element has the specified CSS class

        if @attr('class')
            # Convert class attribute to a list of class names
            classNames = (c for c in @attr('class').split(' '))

            # If the class name isn't in the list add it
            if classNames.indexOf(className) > -1
                return true

        return false

    merge: (element)->
        # Attempt to merge 2 elements. Elements can only merge if a merger
        # function has been defined against either merging elements `mergers`
        # class property.
        #
        # The `mergers` class property is an object mapping class names to
        # functions that handle merging element classes. Merger functions
        # handle merging in either direction.

        # A merge always results in the element being removed so merge and
        # remove must be allowed.
        unless @can('merge') and @can('remove')
            return false

        # Determine if either elements class supports the merge
        if @constructor.mergers[element.type()]
            @constructor.mergers[element.type()](element, this)

        else if element.constructor.mergers[@type()]
            element.constructor.mergers[@type()](element, this)

    mount: ->
        # Mount the element on to the DOM, this method is not designed to be
        # called against the base `Element` class, instead it is typically
        # called using `super()` at the end of an overriding `mount` method.

        # This check enables `mount()` to be called directly against the Element
        # class, however this is not the expected behaviour.
        unless @_domElement
            @_domElement = document.createElement(@tagName())

        sibling = @nextSibling()
        if sibling
            @parent().domElement().insertBefore(
                @_domElement,
                sibling.domElement()
                )
        else
            # Check to see if the parent is a fixture, if so then the element
            # will replace the parent DOM instead of appending it.
            if @isFixed()
                @parent().domElement().parentNode.replaceChild(
                    @_domElement,
                    @parent().domElement()
                    )
                @parent()._domElement = @_domElement

            else
                @parent().domElement().appendChild(@_domElement)

        # Add interaction handlers
        @_addDOMEventListeners()

        # Add the type class
        @_addCSSClass('ce-element')
        @_addCSSClass("ce-element--type-#{ @cssType() }")

        # Add the focused class if the element is focused
        if @isFocused()
            @_addCSSClass('ce-element--focused')

        @root.trigger('mount', this)

    removeAttr: (name)->
        # Remove an attribute from the element
        name = name.toLowerCase()

        # Remove an attribute from the element
        if not @_attributes[name]
            return

        # Remove the attribute
        delete @_attributes[name]

        # Remove the attribute from the DOM element if mounted and we're not
        # removing `class`. CSS classes should always be removed using the
        # `removeCSSClass` method which removes the class from the mounted
        # DOM element whilst maintaining the classes applied for editing.
        if @isMounted() and name.toLowerCase() != 'class'
            @_domElement.removeAttribute(name)

        # Mark as modified
        @taint()

    removeCSSClass: (className)->
        # Remove a CSS class from the element
        if not @hasCSSClass(className)
            return

        # Remove the CSS class
        classNames = (c for c in @attr('class').split(' '))

        # If the class name is in the list remove it
        classNameIndex = classNames.indexOf(className)
        if classNameIndex > -1
            classNames.splice(classNameIndex, 1)

        # If there are not classes left remove the attribute
        if classNames.length
            @attr('class', classNames.join(' '))
        else
            @removeAttr('class')

        # Remove the CSS class from the DOM element
        @_removeCSSClass(className)

        # Mark the element as modified
        @taint()

    tagName: (name)->
        # Get/Set the tag name for the element, the tag name is only set if a
        # value is specified.

        # Get...
        if name == undefined
            return @_tagName

        # ...or Set the tag name
        @_tagName = name.toLowerCase()

        # Re-mount the element if mounted
        if @isMounted()
            @unmount()
            @mount()

        # Mark as modified
        @taint()

    unmount: ->
        # Unmount the element from the DOM

        # Remove event listeners
        @_removeDOMEventListeners()

        # Check if the element is a fixture in which case it cannot be unmounted
        # but instead we must remove any classes applied on mount.
        if @isFixed()
            @_removeCSSClass('ce-element')
            @_removeCSSClass("ce-element--type-#{ @cssType() }")
            @_removeCSSClass('ce-element--focused')

            return

        if @_domElement.parentNode
            @_domElement.parentNode.removeChild(@_domElement)
        @_domElement = null

        # Trigger the unmount event
        @root.trigger('unmount', this)

    # Event handlers

    _addDOMEventListeners: ->
        # Add all event bindings for the DOM element in this method

        # Define all event listeners
        @_domEventHandlers = {
            # Drag events
            'dragstart': (ev)=>
                ev.preventDefault()

            # Focus events
            'focus': (ev)=>
                ev.preventDefault()

            # Keyboard events
            'keydown': (ev)=>
                @_onKeyDown(ev)

            'keyup': (ev)=>
                @_onKeyUp(ev)

            # Mouse events
            'mousedown': (ev)=>
                # The editing environment only uses primary mouse button events
                if ev.button == 0
                    @_onMouseDown(ev)

            'mousemove': (ev)=>
                @_onMouseMove(ev)

            'mouseover': (ev)=>
                @_onMouseOver(ev)

            'mouseout': (ev)=>
                @_onMouseOut(ev)

            'mouseup': (ev)=>
                # The editing environment only primary left mouse button events
                if ev.button == 0
                    @_onMouseUp(ev)

            # Paste event

            'dragover': (ev)=>
                ev.preventDefault()

            'drop': (ev)=>
                @_onNativeDrop(ev)

            'paste': (ev)=>
                @_onPaste(ev)
        }

        # Add all event listeners
        for eventName, eventHandler of @_domEventHandlers
            @_domElement.addEventListener(eventName, eventHandler)

    _onKeyDown: (ev)->
        # No default behaviour

    _onKeyUp: (ev)->
        # No default behaviour

    _onMouseDown: (ev)->
        if @focus
            # We suppress the DOM focus that would normally be inniated as it
            # this helps prevent page jumps when selecting large blocks of
            # content.
            @focus(true)

    _onMouseMove: (ev)->
        @_onOver(ev)

    _onMouseOver: (ev)->
        @_onOver(ev)

    _onMouseOut: (ev)->
        @_removeCSSClass('ce-element--over')

        # If the element is the current drop target we need to remove it
        if @root.dragging()
            @_removeCSSClass('ce-element--drop')
            @_removeCSSClass('ce-element--drop-above')
            @_removeCSSClass('ce-element--drop-below')
            @_removeCSSClass('ce-element--drop-center')
            @_removeCSSClass('ce-element--drop-left')
            @_removeCSSClass('ce-element--drop-right')
            @_factory.root._dropTarget = null

    _onMouseUp: (ev)->
        # No default behaviour

    _onNativeDrop: (ev)->
        # By default we don't support native drop events and external libraries
        # are expected to handle native drop support.
        ev.preventDefault()
        ev.stopPropagation()
        @root.trigger('native-drop', this, ev)

    _onPaste: (ev)->
        # By default we don't support paste events and external libraries
        # are expected to handle paste support.
        ev.preventDefault()
        ev.stopPropagation()
        @root.trigger('paste', this, ev)

    _onOver: (ev) ->
        @_addCSSClass('ce-element--over')

        # Check an elment is currently being dragged
        dragging = @root.dragging()
        unless dragging
            return

        # Check the dragged element isn't this element (can't drop on self)
        unless dragging != this
            return

        # Check we don't already have a drop target
        if @root._dropTarget
            return

        # Check this element is allowed to receive drops
        unless @can('drop')
            return

        # Check the dragged element can be dragged on to this element
        unless (@constructor.droppers[dragging.type()] \
                or dragging.constructor.droppers[@type()])
            return

        # Mark the element as a drop target
        @_addCSSClass('ce-element--drop')
        @root._dropTarget = @

    _removeDOMEventListeners: () ->
        # The method is called before the element is removed from the DOM,
        # whilst it is unnecessary to remove and event listeners bound to the
        # DOM element itself, event listners bound to associated DOM elements
        # should be removed here.

        # Remove all event listeners
        for eventName, eventHandler of @_domEventHandlers
            @_domElement.removeEventListener(eventName, eventHandler)


    # Private methods

    _addCSSClass: (className) ->
        # Add a CSS class to the DOM element (the class is only added to the DOM
        # element, not the elements `class` attribute.
        unless @isMounted()
            return

        addCSSClass(@_domElement, className)

    _attributesToString: () ->
        # Return the attributes for the element as a string
        unless Object.getOwnPropertyNames(@_attributes).length > 0
            return ''

        return ' ' + attributesToString(@_attributes)

    _removeCSSClass: (className) ->
        # Remove a CSS class from the DOM element (the class is only removed
        # from the DOM element, not the elements `class` attribute.
        unless @isMounted()
            return

        removeCSSClass(@_domElement, className)

    # Class properties

    # Map of functions to support dropping dragged elements (see
    # `Element.drop()`).
    @droppers: {}

    # Map of functions to support merging elements (see
    # `Element.merge()`).
    @mergers: {}

    # List of allowed drop placements for the class, supported values are:
    #
    # - above
    # - below
    # - center
    # - left
    # - right
    #
    @placements: ['above', 'below']

    # Class methods

    @getDOMElementAttributes: (domElement)->
        # Return a map of attributes for a DOM element

        # Check if the element has any attributes and if not return an empty map
        unless domElement.hasAttributes()
            return {}

        # Convert the DOM elements name/value attibute array to a map
        attributes = {}
        for attribute in domElement.attributes
            attributes[attribute.name.toLowerCase()] = attribute.value

        return attributes

    # Private class methods

    # The following private methods are useful when defining common drag/drop
    # behaviour for elements.

    @_dropVert: (element, target, placement)->
        # Drop an element above or below another element

        # Remove the element from it's current parent
        element.parent().detach(element)

        # Get the position of the target element we're dropping on to
        insertIndex = target.parent().children.indexOf(target)

        # Determine which side of the target to drop the element
        if placement[0] == 'below'
            insertIndex += 1

        # Drop the element into it's new position
        target.parent().attach(element, insertIndex)

    @_dropBoth: (element, target, placement)->
        # Drop an element above, below, left or right of another element

        # Remove the element from it's current parent
        element.parent().detach(element)

        # Get the position of the target element we're dropping on to
        insertIndex = target.parent().children.indexOf(target)

        # Determine which side of the target to drop the element
        if placement[0] == 'below' and placement[1] == 'center'
            insertIndex += 1

        # Add/Remove alignment classes
        alignLeft = config.ALIGNMENT_CLASS_NAMES['left']
        alignRight = config.ALIGNMENT_CLASS_NAMES['right']

        if element.a
            element._removeCSSClass(alignLeft)
            element._removeCSSClass(alignRight)

            if element.a['class']
                aClassNames = []
                for className in element.a['class'].split(' ')
                    if className == alignLeft or className == alignRight
                        continue
                    aClassNames.push(className)

                if aClassNames.length
                    element.a['class'] = aClassNames.join(' ')
                else
                    delete element.a['class']

        else
            element.removeCSSClass(alignLeft)
            element.removeCSSClass(alignRight)

        if placement[1] == 'left'
            if element.a
                if element.a['class']
                    element.a['class'] += ' ' + alignLeft
                else
                    element.a['class'] = alignLeft
                element._addCSSClass(alignLeft)
            else
                element.addCSSClass(alignLeft)

        if placement[1] == 'right'
            if element.a
                if element.a['class']
                    element.a['class'] += ' ' + alignRight
                else
                    element.a['class'] = alignRight
                element._addCSSClass(alignRight)
            else
                element.addCSSClass(alignRight)

        # Drop the element into it's new position
        target.parent().attach(element, insertIndex)

module.exports = Element
