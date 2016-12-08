UnorderedList = require("./unordered_list")

class OrderedList extends UnorderedList

    # Set an element as an ordered list.

    constructor: (@editor, @tools)->
        @requiresElement = true
        @label = 'Numbers list'
        @icon = 'ordered-list'
        @listTag = 'ol'

module.exports = OrderedList
