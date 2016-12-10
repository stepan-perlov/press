ToolbarTool = require("../toolbar_tool")

class Remove extends ToolbarTool

    # Remove the current element.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Remove'
        @icon = 'delete_forever'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return not element.isFixed()

    apply: (element, selection, callback) ->
        # Apply the tool to the current element

        # Blur the element before it's removed otherwise it will retain focus
        # even when detached.
        element.blur()

        # Focus on the next element
        if element.nextContent()
            element.nextContent().focus()
        else if element.previousContent()
            element.previousContent().focus()

        # Check the element is still mounted (some elements may automatically
        # remove themselves when they lose focus, for example empty text
        # elements.
        if not element.isMounted()
            callback(true)
            return

        # Remove the element
        switch element.type()
            when 'ListItemText'
                # Delete the associated list or list item
                if @editor.ctrlDown()
                    list = element.closest (node) ->
                        return node.parent().type() is 'Region'
                    list.parent().detach(list)
                else
                    element.parent().parent().detach(element.parent())
                break
            when 'TableCellText'
                # Delete the associated table or table row
                if @editor.ctrlDown()
                    table = element.closest (node) ->
                        return node.type() is 'Table'
                    table.parent().detach(table)
                else
                    row = element.parent().parent()
                    row.parent().detach(row)
                break
            else
                element.parent().detach(element)
                break

        callback(true)

module.exports = Remove
