path = require("path")
webpack = require("webpack")
ExtractTextPlugin = require("extract-text-webpack-plugin")

baseConfig = ->
    output:
        path: path.join(__dirname, "build")
        filename: "[name].js"
    devtool : "source-map"
    module:
        loaders: [
            test: /\.css$/
            loader: ExtractTextPlugin.extract("style-loader", "css-loader")
        ,
            test: /\.scss$/
            loader: ExtractTextPlugin.extract("style", "css!sass")
        ,
            test: /\.coffee$/
            loader: "coffee-loader"
        ,
            test: /\.(eot|svg|ttf|woff|woff2)$/
            loader: "file?name=[path][name].[ext]"
        ,
            # https://github.com/webpack/webpack/issues/177
            test: /sinon.*\.js$/
            loader: "imports?define=>false,require=>false"
        ]

    plugins: [
        new ExtractTextPlugin("[name].css")
    ]
    resolve:
        extensions: ["", ".js", ".coffee", ".scss"]
        alias:
            sinon: "sinon/pkg/sinon" # https://github.com/webpack/webpack/issues/177#issuecomment-185718237

module.exports = (argv)->
    config = baseConfig()

    switch argv.app
        when "press"
            config.entry =
                "press-tests": [
                    "webpack-dev-server/client",
                    "./src/tests.coffee"
                ],
                "press-tests-vendor": [
                    "./fonts.scss"
                    "material-design-icons/iconfont/material-icons.css",
                    "material-design-lite/material.js",
                    "material-design-lite/material.css"
                ]
        when "press-dom"
            config.entry =
                "press-dom-tests": [
                    "webpack-dev-server/client",
                    "./src/dom/tests.coffee"
                ]
        else
            throw new Error(
                "Unexpect app: `#{argv.app}`" +
                "Expect: `press`, `press-dom`"
            )

    return config
