webpack = require("webpack")
path = require("path")

baseConfig = ->
    output:
        path: path.join(__dirname, "build")
        filename: "[name].js"
    module:
        loaders: [
            test: /\.css$/
            loader: "style!css"
        ,
            test: /\.coffee$/
            loader: "coffee-loader"
        ]

module.exports = (argv)->
    config = baseConfig()

    switch argv.app
        when "press"
            config.entry =
                "press": "./src/index.coffee"
        when "press-dom"
            config.entry =
                "press-dom": "./src/dom/index.coffee"
        else
            throw new Error(
                "Unexpect app: `#{argv.app}`" +
                "Expect: `press`, `press-dom`"
            )

    return config
