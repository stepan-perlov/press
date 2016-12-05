ToolbarTool = require("../toolbar_tool.coffee")

class AlignLeft extends ToolbarTool

    # Apply a class to left align the contents of the current text block.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Align left'
        @icon = 'align-left'
        @className = 'text-left'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        return element.content != undefined

    isApplied: (element, selection) ->
        # Return true if the tool is currently applied to the current
        # element/selection.
        if not @canApply(element)
            return false

        # List items and table cells use child nodes to manage their content
        # which don't support classes, so we need to check the parent.
        if element.type() in ['ListItemText', 'TableCellText']
            element = element.parent()

        return element.hasCSSClass(@className)

    apply: (element, selection, callback) ->
        # Apply the tool to the current element

        # List items and table cells use child nodes to manage their content
        # which don't support classes, so we need to use the parent.
        if element.type() in ['ListItemText', 'TableCellText']
            element = element.parent()

        # Remove any existing text alignment classes applied
        alignmentClassNames = [
            @tools.align_left.className,
            @tools.align_center.className,
            @tools.align_right.className
        ]
        for className in alignmentClassNames
            if element.hasCSSClass(className)
                element.removeCSSClass(className)

                # If we're removing the class associated with the tool then we
                # can return early (this allows the tool to be toggled on/off).
                if className == @className
                    return callback(true)

        # Add the alignment class to the element
        element.addCSSClass(@className)

        callback(true)

module.exports = AlignLeft
