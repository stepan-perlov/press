path = require "path"

module.exports =
    entry:
        "press": "./src/index.coffee"
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
