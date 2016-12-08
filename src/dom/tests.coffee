require("qunitjs/qunit/qunit.css")
QUnit = require("qunitjs")

require("./_/tests/tests")

require("./base/tests/root")
require("./base/tests/node")
require("./base/tests/node_collection")
require("./base/tests/element")
require("./base/tests/element_collection")
require("./base/tests/resizable_element")

require("./region/tests/region")

require("./text/tests/text")
require("./text/tests/pre_text")

require("./list/tests/list")
require("./list/tests/list_item")
require("./list/tests/list_item_text")

require("./image/tests/image")
require("./video/tests/video")

require("./table/tests/table")
require("./table/tests/table_section")
require("./table/tests/table_row")
require("./table/tests/table_cell")
require("./table/tests/table_cell_text")

QUnit.start()
