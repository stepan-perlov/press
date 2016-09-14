argv = require('yargs').argv
webpack = require("webpack")
configureTest = require("./configure_test.coffee")

compiler = webpack(configureTest())
compiler.watch {}, (err, stats)->
    console.log stats.toString(
        colors: true
    )
