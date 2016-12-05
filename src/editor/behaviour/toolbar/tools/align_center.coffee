AlignLeft = require("./align_left.coffee")

class AlignCenter extends AlignLeft

    # Apply a class to center align the contents of the current text block.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Align center'
        @icon = 'align-center'
        @className = 'text-center'

module.exports = AlignCenter
