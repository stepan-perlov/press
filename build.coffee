argv = require('yargs').argv
webpack = require("webpack")
configureDom = require("./configure-dom.coffee")
configureEditor = require("./configure-editor.coffee")

compiler = webpack(configureDom())
compiler.watch {}, (err, stats)->
    console.log stats.toString(
        colors: true
    )
