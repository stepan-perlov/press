require("qunitjs/qunit/qunit.css")
QUnit = require("qunitjs")

require("./_/tests/tests.coffee")

require("./base/tests/root.coffee")
require("./base/tests/node.coffee")
require("./base/tests/node_collection.coffee")
require("./base/tests/element.coffee")
require("./base/tests/element_collection.coffee")
require("./base/tests/resizable_element.coffee")

require("./region/tests/region.coffee")

require("./text/tests/text.coffee")
require("./text/tests/pre_text.coffee")

require("./list/tests/list.coffee")
require("./list/tests/list_item.coffee")
require("./list/tests/list_item_text.coffee")

require("./image/tests/image.coffee")
require("./video/tests/video.coffee")

QUnit.start()
