Bold = require("./bold")

class Italic extends Bold
    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = "Italic"
        @icon = "italic"
        @tagName = "i"

module.exports = Italic
