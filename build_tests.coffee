path = require("path")
argv = require('yargs')
    .alias("a", "app")
    .argv
webpack = require("webpack")
WebpackDevServer = require("webpack-dev-server")

configureTest = require("./configure_test.coffee")

config = configureTest(argv)
compiler = webpack(config)

server = new WebpackDevServer(
    compiler
    devtool: "eval-source-map"
    publicPath: "http://localhost/../build"
    contentBase: path.join(__dirname, "tests")
    stats: {colors: true}
)

server.listen(8080, "localhost", ->
    webpack(config).watch {}, (err, stats)->
        console.log(err) if err
)
