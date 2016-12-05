path = require("path")
webpack = require("webpack")
configureApp = require("./configure_app.coffee")

argv = require('yargs')
    .alias("a", "app")
    .argv

compiler = webpack(configureApp(argv))
compiler.watch {}, (err, stats)->
    console.log stats.toString(
        colors: true
    )
