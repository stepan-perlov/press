HtmlSelection = require("../../html_selection/html_selection")
config = require("../config")
Element = require("../base/element")
Text = require("../text/text")

class TableCellText extends Text

    # An editable table cell (e.g <td>, <th> -> TEXT_NODE).

    constructor: (@root, content) ->
        super(@root, 'div', {}, content)

    # Read-only properties

    type: () ->
        # Return the type of element (this should be the same as the class name)
        return 'TableCellText'

    _isInFirstRow: () ->
        cell = @parent()
        row = cell.parent()
        section = row.parent()
        table = section.parent()

        if section != table.firstSection()
            return false

        return row == section.children[0]

    _isInLastRow: () ->
        cell = @parent()
        row = cell.parent()
        section = row.parent()
        table = section.parent()

        if section != table.lastSection()
            return false

        return row == section.children[section.children.length - 1]

    _isLastInSection: () ->
        cell = @parent()
        row = cell.parent()
        section = row.parent()
        if row != section.children[section.children.length - 1]
            return false
        return cell == row.children[row.children.length - 1]

    # Methods

    blur: () ->
        # Remove focus from the element

        if @isMounted()

            # Blur the DOM element
            @_domElement.blur()

            # Stop the element from being editable
            @_domElement.removeAttribute('contenteditable')

        # Remove editing focus from this element
        Element::blur.call(@)

    can: (behaviour, allowed) ->
        # The allowed behaviour for a TableCellText instance reflects its parent
        # TableCell and can not be set directly.
        if allowed
            throw new Error('Cannot set behaviour for ListItemText')

        return @parent().can(behaviour)

    html: (indent='') ->
        # Return a HTML string for the node

        # For text elements with optimized output we use a cache to improve
        # performance for repeated calls.
        if not @_lastCached or @_lastCached < @_modified

            # Optimize the content for output
            content = @content.copy().trim()
            content.optimize()

            @_lastCached = Date.now()
            @_cached = content.html()

        return "#{ indent }#{ @_cached }"

    # Event handlers

    _onMouseDown: (ev) ->
        # Give the element focus
        Element::_onMouseDown.call(@, ev)

        # Tables support dragging of individual rows or the table. The drag is
        # initialized by clicking and holding the mouse down on a cell, how long
        # the user holds the mouse down determines which element is dragged (the
        # parent row or table).
        initDrag = () =>
            cell = @parent()
            if @root.dragging() == cell.parent()
                # We're currently dragging the row so switch to dragging the
                # parent table.

                # Cancel dragging the row
                @root.cancelDragging()

                # Find the table and start dragging it
                table = cell.parent().parent().parent()
                table.drag(ev.pageX, ev.pageY)

            else
                # We're not currently dragging anything so start dragging the
                # parent row.
                cell.parent().drag(ev.pageX, ev.pageY)

                # Reset a timeout for this function so that if the user
                # continues to hold down the mouse we can switch to the list
                # root.
                @_dragTimeout = setTimeout(
                    initDrag,
                    config.DRAG_HOLD_DURATION * 2
                    )

        clearTimeout(@_dragTimeout)
        @_dragTimeout = setTimeout(initDrag, config.DRAG_HOLD_DURATION)

    # Key handlers

    _keyBack: (ev) ->
        selection = HtmlSelection.query(@_domElement)
        unless selection.get()[0] == 0 and selection.isCollapsed()
            return

        ev.preventDefault()

        # If this is the first cell in the row and the user the cell is empty
        # check to see if the whole row is empty and if so remove it.
        cell = @parent()
        row = cell.parent()

        # Check we're allowed to delete the row
        if not (row.isEmpty() and row.can('remove'))
            return

        if @content.length() == 0 and row.children.indexOf(cell) == 0

            # Move the focus to the previous text element
            previous = @previousContent()
            if previous
                previous.focus()
                selection = new HtmlSelection(
                    previous.content.length(),
                    previous.content.length()
                    )
                selection.select(previous.domElement())

            # If this is the last row check we're allowed to
            row.parent().detach(row)

    _keyDelete: (ev) ->
        # Check if the row is empty and if it is delete it
        row = @parent().parent()

        # Check we're allowed to delete the row
        if not (row.isEmpty() and row.can('remove'))
            return

        ev.preventDefault()

        # Move the cursor to either the next row (if available) or the
        # next content element.
        lastChild = row.children[row.children.length - 1]
        nextElement = lastChild.tableCellText().nextContent()

        if nextElement
            nextElement.focus()
            selection = new HtmlSelection(0, 0)
            selection.select(nextElement.domElement())

        row.parent().detach(row)

    _keyDown: (ev) ->
        selection = HtmlSelection.query(@_domElement)
        unless @_atEnd(selection) and selection.isCollapsed()
            return

        ev.preventDefault()
        cell = @parent()

        # If this is the last row in the table move out of the section...
        if @_isInLastRow()
            row = cell.parent()
            lastCell = row.children[row.children.length - 1].tableCellText()
            next = lastCell.nextContent()

            if next
                next.focus()
            else
                # If no next element was found this must be the last content
                # node found so trigger an event for external code to manage a
                # region switch.
                @root.trigger(
                    'next-region',
                    @closest (node) ->
                        node.type() is 'Fixture' or node.type() is 'Region'
                    )

        # ...else move down vertically
        else
            nextRow = cell.parent().nextWithTest (node) ->
                return node.type() is 'TableRow'

            cellIndex = cell.parent().children.indexOf(cell)
            cellIndex = Math.min(cellIndex, nextRow.children.length)

            nextRow.children[cellIndex].tableCellText().focus()

    _keyReturn: (ev) ->
        ev.preventDefault()
        @_keyTab({'shiftKey': false, 'preventDefault': () ->})

    _keyTab: (ev) ->
        ev.preventDefault()
        cell = @parent()

        if ev.shiftKey
            # If this is the first child in the first row of the table stop
            if @_isInFirstRow() and cell.parent().children[0] is cell
                return

            # Else move to the previous table cell
            @previousContent().focus()

        else
            # Check if this is the last table cell in a tbody, if it is add
            # another row.
            unless @can('spawn')
                return

            grandParent = cell.parent().parent()
            if grandParent.tagName() == 'tbody' and @_isLastInSection()
                TableRow = require("./table_row.coffee")
                TableCell = require("./table_cell.coffee")

                row = new TableRow(@root)

                # Copy the structure of this row
                for child in cell.parent().children
                    newCell = new TableCell(
                        @root,
                        child.tagName(),
                        child._attributes
                    )
                    newCellText = new TableCellText(@root, '')
                    newCell.attach(newCellText)
                    row.attach(newCell)

                # Add the new row to the section
                section = @closest (node) ->
                    return node.type() is 'TableSection'
                section.attach(row)

                # Move the focus to the first cell in the new row
                row.children[0].tableCellText().focus()

            # If not the last table cell navigate to the next cell
            else
                @nextContent().focus()

    _keyUp: (ev) ->
        selection = HtmlSelection.query(@_domElement)
        unless selection.get()[0] == 0 and selection.isCollapsed()
            return

        ev.preventDefault()
        cell = @parent()

        # If this is the first row in the table move out of the section...
        if @_isInFirstRow()
            row = cell.parent()
            previous = row.children[0].previousContent()

            if previous
                previous.focus()
            else
                # If no previous element was found this must be the first
                # content node found so trigger an event for external code to
                # manage a region switch.
                @root.trigger(
                    'previous-region',
                    @closest (node) ->
                        node.type() is 'Fixture' or node.type() is 'Region'
                    )

        # ...else move up vertically
        else
            previousRow = cell.parent().previousWithTest (node) ->
                return node.type() is 'TableRow'

            cellIndex = cell.parent().children.indexOf(cell)
            cellIndex = Math.min(cellIndex, previousRow.children.length)

            previousRow.children[cellIndex].tableCellText().focus()

    # Class properties

    @droppers: {}

    @mergers: {}

module.exports = TableCellText
