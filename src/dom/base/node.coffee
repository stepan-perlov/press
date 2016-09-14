uniqueId = require("../_/unique_id.coffee")
cssTypeCache = {}

class Node

    # Editable content is structured as a tree, each node in the tree is an
    # instance of a class that inherits from the base `Node` class.

    constructor: (@root)->
        @id = uniqueId(@type())

        # Event bindings for the node
        @_bindings = {}

        # The parent of the node
        @_parent = null

        # The date/time the node was last modified
        @_modified = null

    # Read-only properties

    lastModified: ->
        # Return null if the node is not modified, else return the date/time the
        # node was last modified.
        return @_modified

    parent: ->
        # Return the parent of the node
        return @_parent

    parents: ->
        # Return the ancestors of the node (in ascending order)
        parents = []

        parent = @_parent
        while parent
            parents.push(parent)
            parent = parent._parent

        return parents

    cssType: ->
        typeName = @type()
        unless cssTypeCache[typeName]
            cssTypeName = []
            for char in typeName[0] + typeName.slice(1)
                if char == char.toLowerCase()
                    cssTypeName.push(char)
                else
                    cssTypeName.push("-" + char.toLowerCase())
            cssTypeCache[typeName] = cssTypeName.join("")
        return cssTypeCache[typeName]
    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'Node'

    # Methods

    html: (indent='') ->
        # Return a HTML string for the node
        throw new Error('`html` not implemented')

    # Event methods

    bind: (eventName, callback)->
        # Bind a callback to an event

        # Check a list has been set for the specified event
        if @_bindings[eventName] == undefined
            @_bindings[eventName] = []

        # Add the callback to list for the event
        @_bindings[eventName].push(callback)

        return callback

    trigger: (eventName, args...)->
        # Trigger an event against the node

        # Check we have callbacks to trigger for the event
        unless @_bindings[eventName]
            return

        # Call each function bound to the event
        for callback in @_bindings[eventName]
            if not callback
                continue
            callback.call(this, args...)

    unbind: (eventName, callback)->
        # Unbind a callback from an event

        # If no eventName is specified remove all events
        unless eventName
            @_bindings = {}
            return

        # If no callback is specified remove all callbacks for the event
        unless callback
            @_bindings[eventName] = undefined
            return

        # Check if any callbacks are bound to this event
        unless @_bindings[eventName]
            return

        # Remove the callback from the event
        for suspect, i in @_bindings[eventName]
            if suspect is callback
                @_bindings[eventName].splice(i, 1)

    # Change tracking methods

    commit: ->
        # Mark the node as being unmodified
        @_modified = null

        @root.trigger('commit', this)

    taint: ->
        # Mark the node as being modified
        now = Date.now()
        @_modified = now

        # Mark ancestors as modified
        for parent in @parents()
            parent._modified = now

        # Mark the root as modified
        @root._modified = now

        @root.trigger('taint', this)

    # Navigation methods

    closest: (testFunc)->
        # Find and return the first parent that meets the test condition
        parent = this.parent()
        while parent and not testFunc(parent)
            if parent.parent
                parent = parent.parent()
            else
                parent = null
        return parent

    # The next and previous methods provide a mechanism for navigating elements
    # in the editable content tree as a flat structure.

    next: ->
        # Return the next node in the tree

        # If the node is a populated collection return the first child
        if @children and @children.length > 0
            return @children[0]

        # Look for a next sibling for this node, if we don't find one check each
        # ancestor for one.
        for node in [this].concat(@parents())

            # Check the node is part of a collection, if not there is no next
            # element.
            if not node.parent()
                return null

            children = node.parent().children
            index = children.indexOf(node)

            if index < children.length - 1
                return children[index + 1]

    nextContent: ->
        # Return the next node that supports a content property (e.g
        # `Text`).
        return @nextWithTest (node) ->
            node.content != undefined

    nextSibling: ->
        # Return the nodes next sibling
        index = @parent().children.indexOf(this)

        # Check if this is the last node in the collection in which case there
        # is no next sibiling.
        if index == @parent().children.length - 1
            return null

        return @parent().children[index + 1]

    nextWithTest: (testFunc)->
        # Return the next node that returns true when passed to the `testFunc`
        # function.
        node = this
        while node
            node = node.next()
            if node and testFunc(node)
                return node
        return null

    previous: ->
        # Return the previous element in the tree

        # Check the node is part of a collection, if not there is no previous
        # element.
        if not @parent()
            return null

        # If the node doesn't have a previous sibling then the previous node is
        # the parent.
        children = @parent().children
        if children[0] is this
            return @parent()

        # If the node is a collection find the last child node that either isn't
        # a collection or is an empty collection. The last child in a collection
        # of collections is illustrated below.
        #
        # - a0 (this node)
        #   - b0
        #   - b1
        #   - b2
        #       - c0
        #       - c1 (last child)

        node = children[children.indexOf(this) - 1]
        while node.children and node.children.length
            node = node.children[node.children.length - 1]

        return node

    previousContent: ->
        # Return the previous node that supports a content property (e.g
        # `Text`).
        node = @previousWithTest (node) -> node.content != undefined

    previousSibling: ->
        # Return the nodes previous sibling
        index = @parent().children.indexOf(this)

        # Check if this is the first node in the collection in which case there
        # is no previous sibiling.
        if index == 0
            return null

        return @parent().children[index - 1]

    previousWithTest: (testFunc)->
        # Return the first previous node that returns true when passed to the
        # `testFunc` function.
        node = this
        while node
            node = node.previous()
            if node and testFunc(node)
                return node

    # Class methods
    @extend: (cls) ->
        # Support for extending a class with additional classes

        # Instance properties
        for key, value of cls.prototype
            if key == 'constructor'
                continue
            @::[key] = value

        # Class properties
        for key, value of cls
            if key in '__super__'
                continue
            @::[key] = value

        return @

    @fromDOMElement: (root, domElement)->
        # Convert an element (DOM) to an element of this type
        throw new Error('`fromDOMElement` not implemented')

module.exports = Node
