Heading1 = require("./heading1")

class Heading2 extends Heading1

    # Convert the current text block to a heading (e.g <h2>foo</h2>)

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Heading2'
        @icon = 'heading'
        @tagName = 'h2'

module.exports = Heading2
