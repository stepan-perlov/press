ToolbarTool = require("../toolbar_tool.coffee")

class Unindent extends ToolbarTool

    # Unindent a list item.
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Unindent'
        @icon = 'unindent'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return element.parent().type() is 'ListItem'

    apply: (element, selection, callback) ->
        # Apply the tool to the current element

        # Indent the list item
        element.parent().unindent()

        callback(true)

module.exports = Unindent
