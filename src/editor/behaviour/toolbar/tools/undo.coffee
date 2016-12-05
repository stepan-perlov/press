ToolbarTool = require("../toolbar_tool.coffee")

class Undo extends ToolbarTool
    # Undo an action.

    constructor: (@editor, @tools)->
        @requiresElement = false
        @label = 'Undo'
        @icon = 'undo'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return @editor.history and @editor.history.canUndo()

    apply: (element, selection, callback) ->
        # Revert the document to the previous state
        @editor.history.stopWatching()
        snapshot = @editor.history.undo()
        @editor.revertToSnapshot(snapshot)
        @editor.history.watch()

module.exports = Undo
