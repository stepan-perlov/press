classByTag = require("../class_by_tag")
Element = require("../base/element")
ResizableElement = require("../base/resizable_element")
config = require("../config")
attributesToString = require("../_/attributes_to_string")


class Image extends ResizableElement

    classByTag.associate(@, ["img"])

    # An editable image (e.g <image src="..." alt="foo" width="5" height="5">).
    # The `Image` element supports 2 special tags to allow the the size of the
    # image to be constrained (data-ce-min-width, data-ce--max-width).

    constructor: (@root, attributes, a) ->
        super(@root, 'img', attributes)

        # Optionally an <a> tag may be specified which will wrap the image. The
        # a tag should be specified as a dictionary of attributes.
        @a = if a then a else null

        # Set the aspect ratio for the image based on it's initial width/height
        size = @size()
        @_aspectRatio = size[1] / size[0]

    # Read-only properties

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'Image'

    # Methods

    createDraggingDOMElement: () ->
        # Create a DOM element that visually aids the user in dragging the
        # element to a new location in the editiable tree structure.
        unless @isMounted()
            return

        helper = super()

        # Set the background image for the helper element
        helper.style.backgroundImage = "url(#{ @_attributes['src'] })"

        return helper

    html: (indent='') ->
        # Return a HTML string for the node
        img = "#{ indent }<img#{ @_attributesToString() }>"
        if @a
            attributes = attributesToString(@a)
            attributes = "#{ attributes } data-ce-tag=\"img\""
            return "#{ indent }<a #{ attributes }>\n" +
                "#{ config.INDENT }#{ img }\n" +
                "#{ indent }</a>"
        else
            return img

    mount: () ->
        # Mount the element on to the DOM

        # Create the DOM element to mount
        @_domElement = document.createElement('div')

        # Set the classes for the image, we combine classes from both the outer
        # link tag (if there is one) and image element.
        classes = ''
        if @a and @a['class']
            classes += ' ' + @a['class']

        if @_attributes['class']
            classes += ' ' + @_attributes['class']

        @_domElement.setAttribute('class', classes)

        # Set the background image for the
        style = if @_attributes['style'] then @_attributes['style'] else ''
        style += "background-image:url(#{ @_attributes['src'] });"

        # Set the size using style
        if @_attributes['width']
            style += "width:#{ @_attributes['width'] }px;"

        if @_attributes['height']
            style += "height:#{ @_attributes['height'] }px;"

        @_domElement.setAttribute('style', style)

        super()

    unmount: () ->
        # Unmount the element from the DOM

        if @isFixed()
            # Revert the DOM element to an image
            wrapper = document.createElement('div')
            wrapper.innerHTML = @html()
            domElement = wrapper.querySelector('a, img')

            # Replace the current DOM element with the image
            @_domElement.parentNode.replaceChild(domElement, @_domElement)
            @_domElement = domElement

        super()

    # Class properties

    @droppers:
        'Image': Element._dropBoth
        'PreText': Element._dropBoth
        'Static': Element._dropBoth
        'Text': Element._dropBoth

    # List of allowed drop placements for the class, supported values are:
    @placements: ['above', 'below', 'left', 'right', 'center']

    # Class methods

    @fromDOMElement: (root, domElement) ->
        # Convert an element (DOM) to an element of this type

        # Is the image inside an <a> tag
        a = null
        if domElement.tagName.toLowerCase() == 'a'
            a = @getDOMElementAttributes(domElement)

            # Switch the DOM element to the <img> tag inside it
            childNodes = (c for c in domElement.childNodes)

            # Filter out non-elements
            for childNode in childNodes
                if childNode.nodeType == 1 \
                        and childNode.tagName.toLowerCase() == 'img'
                    domElement = childNode
                    break

            # If we didn't find an image create a blank image
            if domElement.tagName.toLowerCase() == 'a'
                domElement = document.createElement('img')

        # Convert the image
        attributes = @getDOMElementAttributes(domElement)

        # If the width and height of the image haven't been specified, we query
        # the DOM for these values.
        if attributes['width'] is undefined
            if attributes['height'] is undefined
                attributes['width'] = domElement.naturalWidth
            else
                attributes['width'] = domElement.clientWidth

        if attributes['height'] is undefined
            if attributes['width'] is undefined
                attributes['height'] = domElement.naturalHeight
            else
                attributes['height'] = domElement.clientHeight

        return new @(root, attributes, a)

module.exports = Image
