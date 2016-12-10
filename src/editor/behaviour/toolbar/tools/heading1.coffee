ToolbarTool = require("../toolbar_tool")
Text = require("../../../../dom/text/text")

class Heading1 extends ToolbarTool

    # Convert the current text block to a heading (e.g <h1>foo</h1>)

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Heading1'
        @tagName = 'h1'

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.

        if element.isFixed()
            return false

        return element.content != undefined and
                ['Text', 'PreText'].indexOf(element.type()) != -1

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
        element.storeState()

        # If the tag is a PreText tag then we need to handle the convert the
        # element not just the tag name.
        if element.type() is 'PreText'
            # Convert the element to a Text element first
            content = element.content.html().replace(/&nbsp;/g, ' ')
            textElement = new Text(@editor.root, @tagName, {}, content)

            # Remove the current element from the region
            parent = element.parent()
            insertAt = parent.children.indexOf(element)
            parent.detach(element)
            parent.attach(textElement, insertAt)

            # Restore selection
            element.blur()
            textElement.focus()
            textElement.selection(selection)

        else
            # Change the text elements tag name

            # Remove any CSS classes from the element
            element.attr('class', '')

            # If the element already has the same tag name as the tool will
            # apply revert the element to a paragraph.
            if element.tagName() == @tagName
                element.tagName('p')
            else
                element.tagName(@tagName)

            element.restoreState()

        callback(true)

module.exports = Heading1
