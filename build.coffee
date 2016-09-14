argv = require('yargs').argv
webpack = require("webpack")
configureDom = require("./configure_dom.coffee")
configureEditor = require("./configure_editor.coffee")

compiler = webpack(configureDom())
compiler.watch {}, (err, stats)->
    console.log stats.toString(
        colors: true
    )
