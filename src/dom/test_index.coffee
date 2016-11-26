QUnit = require("qunitjs")

require("qunitjs/qunit/qunit.css")
require("./base/test_node.coffee")
require("./base/test_node_collection.coffee")
require("./base/test_element.coffee")
require("./base/test_element_collection.coffee")
require("./base/test_resizable_element.coffee")

require("./text/test_text.coffee")
require("./text/test_pre_text.coffee")

require("./list/test_list.coffee")
require("./list/test_list_item.coffee")
require("./list/test_list_item_text.coffee")

QUnit.start()
