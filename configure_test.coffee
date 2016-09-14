path = require("path")
webpack = require("webpack")
ExtractTextPlugin = require("extract-text-webpack-plugin")

module.exports = (options)->
    entry:
        "press-test": "./src/dom/test_index.coffee"
    output:
        path: path.join(__dirname, "build")
        filename: "[name].js"
    module:
        loaders: [
            test: /\.css$/
            loader: ExtractTextPlugin.extract("style-loader", "css-loader")
        ,
            test: /\.coffee$/
            loader: "coffee-loader"
        ,
            # https://github.com/webpack/webpack/issues/177
            test: /sinon.*\.js$/
            loader: "imports?define=>false,require=>false"
        ]
    plugins: [
        new ExtractTextPlugin("[name].css")
    ]
    resolve:
        alias:
            sinon: "sinon/pkg/sinon" # https://github.com/webpack/webpack/issues/177#issuecomment-185718237
