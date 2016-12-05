ToolbarTool = require("../toolbar_tool.coffee")

class Indent extends ToolbarTool

    # Indent a list item.
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Indent'
        @icon = 'indent'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.

        return element.parent().type() is 'ListItem' and
                element.parent().parent().children.indexOf(element.parent()) > 0

    apply: (element, selection, callback) ->
        # Apply the tool to the current element

        # Indent the list item
        element.parent().indent()

        callback(true)

module.exports = Indent
