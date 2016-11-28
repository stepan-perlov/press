argv = require('yargs').argv
webpack = require("webpack")
WebpackDevServer = require("webpack-dev-server")

configureTest = require("./configure_test.coffee")

config = configureTest()
config.entry = ["webpack/hot/dev-server", config.entry]
compiler = webpack(config)

server = new WebpackDevServer(
    compiler
    devtool: "eval-source-map"
    stats: {colors: true}
)

server.listen(8080, "localhost", ->
    webpack(configureTest()).watch {}, (err, stats)->
        console.log(err) if err
)
