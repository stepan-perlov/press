Node = require("./node")

class NodeCollection extends Node

    # The `NodeCollection` class is used to implement nodes that parent a
    # collection of child nodes (for example the root or a region).

    constructor: (@root)->
        super(@root)

        # The children within the collection
        @children = []

    # Read-only properties

    descendants: ->
        # Return a (flat) list all the decendants

        # Build the list of decendants
        descendants = []
        nodeStack = @children.slice()

        while nodeStack.length > 0
            node = nodeStack.shift()
            descendants.push(node)

            # If the child is a collection add it's children to the stack
            if node.children and node.children.length > 0
                nodeStack = node.children.slice().concat(nodeStack)

        return descendants

    isMounted: ->
        # Return true if the node is mounted in the DOM
        return false

    type: ->
        # Return the type of element (this should be the same as the class name)
        return 'NodeCollection'

    # Methods

    attach: (node, index)->
        # Attach a node to the collection, optionally at the specified index. If
        # no index is specified the node is appended as the last child.

        # If the node is already attached to another collection detach it
        if node.parent()
            node.parent().detach(node)

        # Set the new parent for the node as this collection
        node._parent = this

        # Insert the node into the collection
        if index != undefined
            @children.splice(index, 0, node)
        else
            @children.push(node)

        # If the node is an element mount it on the DOM
        if node.mount and @isMounted()
            node.mount()

        # Mark the colleciton as modified
        @taint()

        @root.trigger('attach', this, node)

    commit: ->
        # Mark the node and all of it's children as being unmodified

        # Silently mark all the children as unmodified
        for descendant in @descendants()
            descendant._modified = null

        # Commit collection
        @_modified = null

        @root.trigger('commit', this)

    detach: (node)->
        # Detach the specified node from the collection

        # Find the node in the collection (if not found return)
        nodeIndex = @children.indexOf(node)
        if nodeIndex == -1
            return

        # If the node is an element unmount it from the DOM
        if node.unmount and @isMounted() and node.isMounted()
            node.unmount()

        # Remove the element from the collection
        @children.splice(nodeIndex, 1)

        # Set the parent to null
        node._parent = null

        # Mark the collection as modified
        @taint()

        @root.trigger('detach', this, node)

module.exports = NodeCollection
