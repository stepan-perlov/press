QUnit = require("qunitjs")
config = require("../../config")
i18n = require("../i18n")
addCSSClass = require("../add_css_class")
removeCSSClass = require("../remove_css_class")
attributesToString = require("../attributes_to_string")

QUnit.module "press.dom._"

QUnit.test "i18n()", (assert)->
    i18n.addLanguage(
        "ru", {
            "hello": "привет"
        }
    )

    assert.equal i18n("hello"), "hello"

    config.LANGUAGE = "ru"
    assert.equal i18n("hello"), "привет"
    assert.equal i18n("world"), "world"

    config.LANGUAGE = "en"

QUnit.test "addCSSClass()", (assert)->
    domElement = document.createElement("div")

    addCSSClass(domElement, "class1")
    assert.equal domElement.getAttribute("class"), "class1"

    addCSSClass(domElement, "class2")
    assert.equal domElement.getAttribute("class"), "class1 class2"

QUnit.test "removeCSSClass()", (assert)->
    domElement = document.createElement("div")

    addCSSClass(domElement, "class1")
    addCSSClass(domElement, "class2")
    assert.equal domElement.getAttribute("class"), "class1 class2"

    removeCSSClass(domElement, "class2")
    assert.equal domElement.getAttribute("class"), "class1"

    removeCSSClass(domElement, "class1")
    assert.strictEqual domElement.getAttribute("class"), null

QUnit.test "attributesToString()", (assert)->
    attributes = {
        "id": "id1",
        "class": "class1"
    }
    assert.equal attributesToString(attributes), "class=\"class1\" id=\"id1\""
