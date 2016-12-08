ToolbarTool = require("../toolbar_tool")

class Redo extends ToolbarTool
    # Redo an action.

    constructor: (@editor, @tools)->
        @requiresElement = false
        @label = 'Redo'
        @icon = 'redo'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return @editor.history and @editor.history.canRedo()

    apply: (element, selection, callback) ->
        # Revert the document to the next state
        @editor.history.stopWatching()
        snapshot = @editor.history.redo()
        @editor.revertToSnapshot(snapshot)
        @editor.history.watch()

module.exports = Redo
