AlignLeft = require("./align_left")

class AlignRight extends AlignLeft

    # Apply a class to right align the contents of the current text block.
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Align right'
        @icon = 'align-right'
        @className = 'text-right'

module.exports = AlignRight
