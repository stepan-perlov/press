ToolbarTool = require("../toolbar_tool")

class Image extends ToolbarTool

    # Indent a list item.
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Image'
        @icon = 'insert_photo'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return true

    apply: (element, selection, callback) ->
        # Apply the tool to the current element
        @editor.root.trigger("image:apply", element, selection, callback)

module.exports = Image
