ToolbarTool = require("../toolbar_tool.coffee")
List = require("../../../../dom/list/list.coffee")
ListItem = require("../../../../dom/list/list_item.coffee")
ListItemText = require("../../../../dom/list/list_item_text.coffee")

class UnorderedList extends ToolbarTool

    # Set an element as an unordered list.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Bullet list'
        @icon = 'unordered-list'
        @listTag = 'ul'

    canApply: (element, selection) ->

        if element.isFixed()
            return false

        # Return true if the tool can be applied to the current
        # element/selection.
        return element.content != undefined and
                element.parent().type() in ['Region', 'ListItem']

    apply: (element, selection, callback) ->
        # Apply the tool to the current element
        if element.parent().type() is 'ListItem'

            # Find the parent list and change it to an unordered list
            element.storeState()
            list = element.closest (node) ->
                return node.type() is 'List'
            list.tagName(@listTag)
            element.restoreState()

        else
            # Convert the element to a list

            # Create a new list using the current elements content
            listItemText = new ListItemText(@editor.root, element.content.copy())
            listItem = new ListItem(@editor.root)
            listItem.attach(listItemText)
            list = new List(@editor.root, @listTag, {})
            list.attach(listItem)

            # Remove the current element from the region
            parent = element.parent()
            insertAt = parent.children.indexOf(element)
            parent.detach(element)
            parent.attach(list, insertAt)

            # Restore selection
            listItemText.focus()
            listItemText.selection(selection)

        callback(true)

module.exports = UnorderedList
