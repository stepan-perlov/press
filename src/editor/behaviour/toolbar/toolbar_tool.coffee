class ToolbarTool
    # Most tools require an element that they can be applied to, but there are
    # exceptions (such as undo/redo). In these cases you can set the
    # `requiresElement` flag to false so that the toolbox will not automatically
    # disable the tool because there is not element focused.
    constructor: (@editor, @_tools)->
        throw new Error('Not implemented')

    # Return true if the tool can be applied to the specified
    # element and selection.
    canApply: (element, selection)-> false

    # Return true if the tool is currently applied to the specified
    # element and selection.
    isApplied: (element, selection)-> false

    # Apply the tool to the specified element and selection
    apply: (element, selection, callback) -> throw new Error('Not implemented')

    # Find insert node and index for inserting an element after the
    # specified element.
    _insertAt: (element) ->
        insertNode = element
        if insertNode.parent().type() != 'Region'
            insertNode = element.closest((node)-> node.parent().type() is 'Region')

        insertIndex = insertNode.parent().children.indexOf(insertNode) + 1

        return [insertNode, insertIndex]

module.exports = ToolbarTool
