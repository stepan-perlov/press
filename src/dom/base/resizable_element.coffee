Element = require("./element.coffee")
config = require("../config.coffee")

class ResizableElement extends Element

    # The `ResizableElement` class is used to implement elements that can be
    # resized (for example an image or video).

    constructor: (root, tagName, attributes) ->
        super(root, tagName, attributes)

        # The DOM element used to display size information for the element
        @_domSizeInfoElement = null

        # The aspect ratio of the element
        @_aspectRatio = 1

    # Read-only properties

    aspectRatio: () ->
        # Return the aspect ratio of the element (ratio = height / width)
        #
        # NOTE: The aspect ratio is typically set when the element is
        # constructed, it is down to the inheriting element to determine if,
        # when and how it may be updated after that. It is not safe to calculate
        # the aspect ratio on the fly as casting the width/height of the element
        # to an integer (for example when resizing) can alter the ratio.

        return @_aspectRatio

    maxSize: () ->
        # Return the maximum size the element can be set to (use the
        # `data-ce-max-width` attribute to set this).
        #
        # NOTE: By default `maxSize` only considers the width and calculates the
        # height based on the elements aspect ratio. For elements that support a
        # non-fixed aspect ratio this method should be overridden to support
        # querying for a maximum height.

        # Determine the maximum width allowed for the element
        maxWidth = parseInt(@attr('data-ce-max-width') or 0)
        if not maxWidth
            maxWidth = config.DEFAULT_MAX_ELEMENT_WIDTH

        # The maximum width cannot be less than the current width
        maxWidth = Math.max(maxWidth, @size()[0])

        return [maxWidth, maxWidth * @aspectRatio()]

    minSize: () ->
        # Return the minimum size the element can be set to (use the
        # `data-ce-min-width` attribute to set this).
        #
        # NOTE: By default `minSize` only considers the width and calculates the
        # height based on the elements aspect ratio. For elements that support a
        # non-fixed aspect ratio this method should be overridden to support
        # querying for a minimum height.

        # Determine the minimum width allowed for the element
        minWidth = parseInt(@attr('data-ce-min-width') or 0)
        if not minWidth
            minWidth = config.DEFAULT_MIN_ELEMENT_WIDTH

        # The minimum width cannot be greater than the current width
        minWidth = Math.min(minWidth, @size()[0])

        return [minWidth, minWidth * @aspectRatio()]

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'ResizableElement'

    # Methods

    mount: () ->
        # Mount the element on to the DOM
        super()

        # Add the size info DOM element
        @_domElement.setAttribute('data-ce-size', @_getSizeInfo())

    resize: (corner, x, y) ->
        # Resize the element
        unless @isMounted() and @can('resize')
            return

        @root.startResizing(this, corner, x, y, true)

    size: (newSize) ->
        # Get/Set the size of the element

        # If a new size hasn't been provided return the size of the element
        if not newSize
            width = parseInt(@attr('width') or 1)
            height = parseInt(@attr('height') or 1)
            return [width, height]

        # Ensure the elements size is set as whole pixels
        newSize[0] = parseInt(newSize[0])
        newSize[1] = parseInt(newSize[1])

        # Apply min/max size constraints

        # Min
        minSize = @minSize()
        newSize[0] = Math.max(newSize[0], minSize[0])
        newSize[1] = Math.max(newSize[1], minSize[1])

        # Max
        maxSize = @maxSize()
        newSize[0] = Math.min(newSize[0], maxSize[0])
        newSize[1] = Math.min(newSize[1], maxSize[1])

        # Set the size of the element as attributes
        @attr('width', parseInt(newSize[0]))
        @attr('height', parseInt(newSize[1]))

        if @isMounted()

            # Set the size of the element using style
            @_domElement.style.width = "#{ newSize[0] }px"
            @_domElement.style.height = "#{ newSize[1] }px"

            # Update the size info
            @_domElement.setAttribute('data-ce-size', @_getSizeInfo())

    # Event handlers

    _onMouseDown: (ev) ->
        super(ev)

        # Drag or Resize the element
        corner = @_getResizeCorner(ev.clientX, ev.clientY)
        if corner
            @resize(corner, ev.clientX, ev.clientY)
        else
            # We add a small delay to prevent drag engaging instantly
            clearTimeout(@_dragTimeout)
            @_dragTimeout = setTimeout(
                () =>
                    @drag(ev.pageX, ev.pageY)
                150
                )

    _onMouseMove: (ev) ->
        super()

        unless @can('resize')
            return

        # Add/Remove any resize classes
        @_removeCSSClass('ce-element--resize-top-left')
        @_removeCSSClass('ce-element--resize-top-right')
        @_removeCSSClass('ce-element--resize-bottom-left')
        @_removeCSSClass('ce-element--resize-bottom-right')

        corner = @_getResizeCorner(ev.clientX, ev.clientY)
        if corner
            @_addCSSClass("ce-element--resize-#{ corner[0] }-#{ corner[1] }")

    _onMouseOut: (ev) ->
        super()

        # Remove any resize classes
        @_removeCSSClass('ce-element--resize-top-left')
        @_removeCSSClass('ce-element--resize-top-right')
        @_removeCSSClass('ce-element--resize-bottom-left')
        @_removeCSSClass('ce-element--resize-bottom-right')

    _onMouseUp: (ev) ->
        super()

        # If we're waiting to see if the user wants to drag the element, stop
        # waiting they don't.
        if @_dragTimeout
            clearTimeout(@_dragTimeout)

    # Private methods

    _getResizeCorner: (x, y) ->
        # If the cursor is in the corner of the element such that it would
        # trigger a resize return the corner as 'top/bottom-left/right'.

        # Calculate the relative position of the cursor to the element
        rect = @_domElement.getBoundingClientRect()
        [x, y] = [x - rect.left, y - rect.top]

        # Determine the size of the corner region, whilst there is a default
        # size we must also ensure that for small elements the default doesn't
        # make it impossible to interact with the element
        size = @size()
        cornerSize = config.RESIZE_CORNER_SIZE
        cornerSize = Math.min(cornerSize, Math.max(parseInt(size[0] / 4), 1))
        cornerSize = Math.min(cornerSize, Math.max(parseInt(size[1] / 4), 1))

        # Determine if the user has clicked in a corner of the element, and if
        # so which corner.
        corner = null
        if x < cornerSize
            if y < cornerSize
                corner = ['top', 'left']
            else if y > rect.height - cornerSize
                corner = ['bottom', 'left']

        else if x > rect.width - cornerSize
            if y < cornerSize
                corner = ['top', 'right']
            else if y > rect.height - cornerSize
                corner = ['bottom', 'right']

        return corner

    _getSizeInfo: () ->
        # Return a string that should be displayed inside the size info element
        size = @size()
        return "w #{ size[0] } × h #{ size[1] }"

module.exports = ResizableElement
