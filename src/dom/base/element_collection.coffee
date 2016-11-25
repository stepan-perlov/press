Element = require("./element.coffee")
NodeCollection = require("./node_collection.coffee")
config = require("../config.coffee")

class ElementCollection extends Element

    # The `ElementCollection` class is used to implement elements that parent
    # a collection of child elements (for example a list or a table row).

    @extend NodeCollection

    constructor: (@root, tagName, attributes)->
        super(@root, tagName, attributes)
        NodeCollection::constructor.call(@, @root)

    # Read-only properties

    isMounted: ->
        # Return true if the element collection is mounted
        return @_domElement != null

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'ElementCollection'

    # Methods

    createDraggingDOMElement: ->
        # Create a DOM element that visually aids the user in dragging the
        # collection to a new location in the editable tree structure.
        unless @isMounted()
            return

        helper = super()

        # Use the body of the node to create the helper but limit the text to
        # something sensible.
        text = @_domElement.textContent
        if text.length > config.HELPER_CHAR_LIMIT
            text = text.substr(0, config.HELPER_CHAR_LIMIT)

        helper.innerHTML = text

        return helper

    detach: (element)->
        # Detach the specified element from the collection
        NodeCollection::detach.call(this, element)

        # Remove the collection if it's empty
        if @children.length == 0 and @parent()
            @parent().detach(this)

    html: (indent='')->
        # Return a HTML string for the node
        children = (c.html(indent + config.INDENT) for c in @children)

        if @isFixed()
            return children.join('\n')

        else
            return "#{ indent }<#{ @tagName() }#{ @_attributesToString() }>\n" +
                "#{ children.join('\n') }\n" +
                "#{ indent }</#{ @tagName() }>"

    mount: ->
        # Mount the element on to the DOM

        # Create the DOM element to mount
        @_domElement = document.createElement(@_tagName)

        # Set the attributes
        for name, value of @_attributes
            @_domElement.setAttribute(name, value)

        super()

        # Mount all the children
        for child in @children
            child.mount()

    unmount: ->
        # Unmount the element from the DOM

        # Unmount all the children
        for child in @children
            child.unmount()

        super()

    # NOTE: Collections cannot receive focus.
    blur: undefined
    focus: undefined

module.exports = ElementCollection
