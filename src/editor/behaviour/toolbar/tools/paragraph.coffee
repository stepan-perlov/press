ToolbarTool = require("../toolbar_tool")
Text = require("../../../../dom/text/text")

class Paragraph extends ToolbarTool

    # Convert the current text block to a paragraph (e.g <p>foo</p>)

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Paragraph'
        @tagName = 'p'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.

        if element.isFixed()
            return false

        return element != undefined

    isApplied: (element, selection) ->
        # Return true if the tool is currently applied to the current
        # element/selection.
        if not element.content
            return false

        if ['Text', 'PreText'].indexOf(element.type()) == -1
            return false

        return element.tagName() == @tagName

    apply: (element, selection, callback) ->
        # Apply the tool to the current element
        forceAdd = @editor.ctrlDown()

        if @tools.heading1.canApply(element) and not forceAdd
            # If the element is a top level text element and the user hasn't
            # indicated they want to force add a new paragraph convert it to a
            # paragraph in-place.
            return @tools.heading1.apply.call(@, element, selection, callback)
        else
            # If the element isn't a text element find the nearest top level
            # node and insert a new paragraph element after it.
            if element.parent().type() != 'Region'
                element = element.closest (node) ->
                    return node.parent().type() is 'Region'

            region = element.parent()
            paragraph = new Text(@editor.root, 'p')
            region.attach(paragraph, region.children.indexOf(element) + 1)

            # Give the newely inserted paragraph focus
            paragraph.focus()

            callback(true)

module.exports = Paragraph
