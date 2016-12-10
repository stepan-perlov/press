ToolbarTool = require("../toolbar_tool")
# TODO: modal

class Link extends ToolbarTool

    # Insert/Remove a link.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Link'
        @icon = 'insert_link'
        @tagName = 'a'

    getAttr: (attrName, element, selection) ->
        # Get an attribute for the element and selection

        # Images
        if element.type() is 'Image'
            if element.a
                return element.a[attrName]

        # Text
        else
            # Find the first character in the selected text that has an `a` tag
            # and return the named attributes value.
            [from, to] = selection.get()
            selectedContent = element.content.slice(from, to)
            for c in selectedContent.characters
                if not c.hasTags('a')
                    continue

                for tag in c.tags()
                    if tag.name() == 'a'
                        return tag.attr(attrName)

        return ''

    canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        if element.type() is 'Image'
            return true
        else
            # Must support content
            unless element.content
                return false

            # A selection must exist
            if not selection
                return false

            # If the selection is collapsed then it must be within an existing
            # link.
            if selection.isCollapsed()
                character = element.content.characters[selection.get()[0]]
                if not character or not character.hasTags('a')
                    return false

            return true

    isApplied: (element, selection) ->
        # Return true if the tool is currently applied to the current
        # element/selection.
        if element.type() is 'Image'
            return element.a
        else
            return super(element, selection)

    apply: (element, selection, callback) ->
        applied = false

        # Prepare text elements for adding a link
        if element.type() is 'Image'
            # Images
            rect = element.domElement().getBoundingClientRect()

        else
            # If the selection is collapsed then we need to select the entire
            # entire link.
            if selection.isCollapsed()

                # Find the bounds of the link
                characters = element.content.characters
                starts = selection.get(0)[0]
                ends = starts

                while starts > 0 and characters[starts - 1].hasTags('a')
                    starts -= 1

                while ends < characters.length and characters[ends].hasTags('a')
                    ends += 1

                # Select the link in full
                selection = new ContentSelect.Range(starts, ends)
                selection.select(element.domElement())

            # Text elements
            element.storeState()

            # Add a fake selection wrapper to the selected text so that it
            # appears to be selected when the focus is lost by the element.
            selectTag = new HTMLString.Tag('span', {'class': 'ct--puesdo-select'})
            [from, to] = selection.get()
            element.content = element.content.format(from, to, selectTag)
            element.updateInnerHTML()

            # Measure a rectangle of the content selected so we can position the
            # dialog centrally.
            domElement = element.domElement()
            measureSpan = domElement.getElementsByClassName('ct--puesdo-select')
            rect = measureSpan[0].getBoundingClientRect()

        # Set-up the dialog

        # Modal
        modal = new ContentTools.ModalUI(transparent=true, allowScrolling=true)

        # When the modal is clicked on the dialog should close
        modal.addEventListener 'click', () ->
            @unmount()
            dialog.hide()

            if element.content
                # Remove the fake selection from the element
                element.content = element.content.unformat(from, to, selectTag)
                element.updateInnerHTML()

                # Restore the selection
                element.restoreState()

            callback(applied)

        # Dialog
        dialog = new ContentTools.LinkDialog(
            @getAttr('href', element, selection),
            @getAttr('target', element, selection)
            )

        # Get the scroll position required for the dialog
        [scrollX, scrollY] = ContentTools.getScrollPosition()

        dialog.position([
            rect.left + (rect.width / 2) + scrollX,
            rect.top + (rect.height / 2) + scrollY
            ])

        dialog.addEventListener 'save', (ev) ->
            detail = ev.detail()

            applied = true

            # Add the link
            if element.type() is 'Image'

                # Images
                #
                # Note: When we add/remove links any alignment class needs to be
                # moved to either the link (on adding a link) or the image (on
                # removing a link). Alignment classes are mutually exclusive.
                alignmentClassNames = [
                    'align-center',
                    'align-left',
                    'align-right'
                    ]

                if detail.href
                    element.a = {
                        href: detail.href,
                        target: if detail.target then detail.target else ''
                        class: if element.a then element.a['class'] else ''
                    }
                    for className in alignmentClassNames
                        if element.hasCSSClass(className)
                            element.removeCSSClass(className)
                            element.a['class'] = className
                            break

                else
                    linkClasses = []
                    if element.a['class']
                        linkClasses = element.a['class'].split(' ')
                    for className in alignmentClassNames
                        if linkClasses.indexOf(className) > -1
                            element.addCSSClass(className)
                            break
                    element.a = null

                element.unmount()
                element.mount()

            else
                # Text elements

                # Clear any existing link
                element.content = element.content.unformat(from, to, 'a')

                # If specified add the new link
                if detail.href
                    a = new HTMLString.Tag('a', detail)
                    element.content = element.content.format(from, to, a)
                    element.content.optimize()

                element.updateInnerHTML()

            # Make sure the element is marked as tainted
            element.taint()

            # Close the modal and dialog
            modal.dispatchEvent(modal.createEvent('click'))

        @editor.attach(modal)
        @editor.attach(dialog)
        modal.show()
        dialog.show()
