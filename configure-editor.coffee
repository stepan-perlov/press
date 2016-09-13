path = require("path")

module.exports = (options)->
    entry:
        "press-editor": "./src/editor/index.coffee"
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
