HTMLTag = require("../../../../html_string/html_tag.coffee")
ToolbarTool = require("../toolbar_tool.coffee")

class Bold extends ToolbarTool
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = "Bold"
        @icon = "bold"
        @tagName = "b"

    # Return true if the tool can be applied to the current
    # element/selection.
    canApply: (element, selection) ->
        unless element.content
            return false

        return selection and not selection.isCollapsed()

    # Return true if the tool is currently applied to the current
    # element/selection.
    isApplied: (element, selection) ->
        if element.content is undefined or not element.content.length()
            return false

        [from, to] = selection.get()
        if from == to
            to += 1

        return element.content.slice(from, to).hasTags(@tagName, true)

    # Apply the tool to the current element
    apply: (element, selection, callback) ->
        element.storeState()

        [from, to] = selection.get()

        if @isApplied(element, selection)
            element.content = element.content.unformat(
                from,
                to,
                new HTMLTag(@tagName)
            )
        else
            element.content = element.content.format(
                from,
                to,
                new HTMLTag(@tagName)
            )

        element.content.optimize()
        element.updateInnerHTML()
        element.taint()

        element.restoreState()

        callback(true)

module.exports = Bold
