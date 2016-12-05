Heading1 = require("./heading1.coffee")

class Heading4 extends Heading1

    # Convert the current text block to a heading (e.g <h4>foo</h4>)

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Heading4'
        @icon = 'heading'
        @tagName = 'h4'

module.exports = Heading4
