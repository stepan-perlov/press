toolsFactory = require("./tools/index")

class Toolbar
    # The `Toolbar` class allows tools to be stored using a name (string) as a
    # reference. Using a tools name makes is cleaner when defining a set of
    # tools to populate the `ToolboxUI` widget.

    constructor: (@editor, tools)->
        @tools = {}
        for toolGroup in tools
            for tool in toolGroup
                @tools[tool] = new toolsFactory[tool](@editor, @tools)
    get: (name)->
        unless @tools[name]
            throw new Error("`#{name}` has not been enabled on the toolbar")

        @tools[name]

module.exports = Toolbar
