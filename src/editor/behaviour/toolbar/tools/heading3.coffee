Heading1 = require("./heading1")

class Heading3 extends Heading1

    # Convert the current text block to a heading (e.g <h3>foo</h3>)

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Heading3'
        @icon = 'heading'
        @tagName = 'h3'

module.exports = Heading3
