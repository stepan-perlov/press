require("qunitjs/qunit/qunit.css")
QUnit = require("qunitjs")

require("./base/tests/node.coffee")
require("./base/tests/node_collection.coffee")
require("./base/tests/element.coffee")
require("./base/tests/element_collection.coffee")
require("./base/tests/resizable_element.coffee")

require("./text/tests/text.coffee")
require("./text/tests/pre_text.coffee")

require("./list/tests/list.coffee")
require("./list/tests/list_item.coffee")
require("./list/tests/list_item_text.coffee")

QUnit.start()
