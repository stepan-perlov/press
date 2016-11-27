QUnit = require("qunitjs")
sinon = require("sinon")
Root = require("../root.coffee")
Node = require("../node.coffee")
NodeCollection = require("../node_collection.coffee")
Text = require("../../text/text.coffee")

QUnit.module "press.dom.Node",
    beforeEach: ->
        @root = new Root()
        @node = new Node(@root)

QUnit.test "Node.root", (assert)->
    assert.equal @node.root, @root, "@root should exists"

QUnit.test "Node.lastModified()", (assert)->
    assert.equal @node.lastModified(), null, "Initially the node should not be marked as modified"

QUnit.test "Node.parent()", (assert)->
    parent = new NodeCollection(@root)
    parent.attach(@node)

    assert.equal @node.parent(), parent, "should return the parent node collection for the node"

QUnit.test "Node.parents()", (assert)->
    grandParent = new NodeCollection(@root)
    parent = new NodeCollection(@root)
    grandParent.attach(parent)
    parent.attach(@node)

    assert.deepEqual @node.parents(), [parent, grandParent], "should return an ascending list of all the node's parents"

QUnit.test "Node.html()", (assert)->
    assert.throws @node.html, /`html` not implemented/, "should be abstract method"

QUnit.test "Node.type()", (assert)->
    assert.equal @node.type(), "Node", "should return `Node`"

QUnit.test "Node.bind()", (assert)->
    testValue = key: 0
    testObject =
        firstCallback: -> testValue.key = 1
        secondCallback: -> testValue.key = 2
    firstSpy = sinon.spy testObject, "firstCallback"
    secondSpy = sinon.spy testObject, "secondCallback"

    @node.bind("fire", testObject.firstCallback)
    @node.bind("fire", testObject.secondCallback)
    @node.trigger("fire")

    assert.ok firstSpy.called, "First callback should be called"
    assert.ok secondSpy.called, "Second callback should be called"
    assert.equal testValue.key, 2, "testValue.key should replace secondCallback"

QUnit.test "Node.trigger()", (assert)->
    spy = sinon.spy()

    @node.bind("fire", spy)
    @node.trigger("fire", 1, 2, 3, 4)

    assert.ok spy.calledWith(1, 2, 3, 4), "should trigger an event against the node with specified arguments"

QUnit.test "Node.unbind()", (assert)->
    firstSpy = sinon.spy()
    secondSpy = sinon.spy()

    @node.bind("fire", firstSpy)
    @node.bind("fire", secondSpy)
    @node.unbind("fire")
    @node.trigger("fire")

    assert.notOk firstSpy.called, "should canceled first spy"
    assert.notOk secondSpy.called, "should canceled second spy"

    @node.bind("fire", firstSpy)
    @node.bind("fire", secondSpy)
    @node.unbind("fire", firstSpy)
    @node.trigger("fire")

    assert.notOk firstSpy.called, "should canceled first spy"
    assert.ok secondSpy.called, "should called second spy"

QUnit.test "Node.commit()", (assert)->
    spy = sinon.spy()
    @root.bind("commit", spy)

    @node.taint()
    @node.commit()

    assert.equal @node.lastModified(), null, "should set the last modified date of the node to null"
    assert.ok spy.called, "should trigger the commit event against the root"

QUnit.test "Node.taint()", (assert)->
    spy = sinon.spy()
    @root.bind("taint", spy)

    parent = new NodeCollection(@root)
    parent.attach(@node)
    @node.taint()

    assert.notEqual @node.lastModified(), null, "Should return a date last modified if the node has been tainted"
    assert.equal @node.lastModified(), parent.lastModified(), "Should set last modified to parent"
    assert.equal @node.lastModified(), @root.lastModified(), "Should set last modified to root"
    assert.ok spy.called, "should trigger the taint event against the root"

QUnit.test "Node.closest()", (assert)->
    grandParent = new NodeCollection(@root)
    parent = new NodeCollection(@root)

    grandParent.attach(parent)
    parent.attach(@node)

    grandParent.testFlag = true
    parent.testFlag = false

    assert.equal @node.closest((node)-> node.testFlag), grandParent, "Should return grandParent"
    assert.equal @node.closest((node)-> !node.testFlag), parent, "Should return parent"
    assert.equal @node.closest((node)-> false), null, "Should return null"

QUnit.test "Node.next()", (assert)->
    parent = new NodeCollection(@root)
    siblingCollection = new NodeCollection(@root)
    siblingCollectionChild = new Node(@root)
    siblingNode = new Node(@root)

    parent.attach(@node)
    parent.attach(siblingCollection)
    siblingCollection.attach(siblingCollectionChild)
    parent.attach(siblingNode)

    assert.equal @node.next(), siblingCollection, "Must return next collection"
    assert.equal @node.next().next(), siblingCollectionChild, "Must return next collection child"
    assert.equal @node.next().next().next(), siblingNode, "Must return next node"
    assert.equal @node.next().next().next().next(), null, "Must return null"

QUnit.test "Node.nextContent()", (assert)->
    parent = new NodeCollection(@root)
    sibling = new NodeCollection(@root)
    siblingChild = new Text(@root, "p", {}, "testing")

    parent.attach(@node)
    parent.attach(sibling)
    sibling.attach(siblingChild)

    assert.equal @node.nextContent(), siblingChild, "Must return text node"

QUnit.test "Node.nextSibling()", (assert)->
    parent = new NodeCollection(@root)
    siblingCollection = new NodeCollection(@root)
    siblingCollectionChild = new Node(@root)
    siblingNode = new Node(@root)

    parent.attach(@node)
    parent.attach(siblingCollection)
    siblingCollection.attach(siblingCollectionChild)
    parent.attach(siblingNode)

    assert.equal @node.nextSibling(), siblingCollection, "Must return next collection"
    assert.equal @node.nextSibling().nextSibling(), siblingNode, "Must return next node"
    assert.equal @node.nextSibling().nextSibling().nextSibling(), null, "Must return null"

QUnit.test "Node.nextWithTest()", (assert)->
    parent = new NodeCollection(@root)
    nextNode = new NodeCollection(@root)
    nextNodeChild = new Node(@root)

    parent.attach(@node)
    parent.attach(nextNode)
    parent.attach(nextNodeChild)

    nextNodeChild.testFlag = true

    assert.equal @node.nextWithTest((node)-> node.testFlag), nextNodeChild, "should return the next node in the tree that matches"
    assert.equal @node.nextWithTest((node)-> false), null, "should return null"

QUnit.test "Node.previous()", (assert)->
    parent = new NodeCollection(@root)
    siblingNode = new Node(@root)
    siblingCollection = new NodeCollection(@root)
    siblingCollectionChild = new Node(@root)


    parent.attach(siblingNode)
    parent.attach(siblingCollection)
    siblingCollection.attach(siblingCollectionChild)
    parent.attach(@node)

    assert.equal @node.previous(), siblingCollectionChild, "Must return previous collection child"
    assert.equal @node.previous().previous(), siblingCollection, "Must return previous collection"
    assert.equal @node.previous().previous().previous(), siblingNode, "Must return previous node"
    assert.equal @node.previous().previous().previous().previous(), parent, "Must return parent"
    assert.equal @node.previous().previous().previous().previous().previous(), null, "Must return null"

QUnit.test "Node.previousContent()", (assert)->
    parent = new NodeCollection(@root)
    sibling = new NodeCollection(@root)
    siblingChild = new Text(@root, "p", {}, "testing")

    parent.attach(sibling)
    sibling.attach(siblingChild)
    parent.attach(@node)

    assert.equal @node.previousContent(), siblingChild, "Must return text node"

QUnit.test "Node.previousSibling()", (assert)->
    parent = new NodeCollection(@root)
    siblingNode = new Node(@root)
    siblingCollection = new NodeCollection(@root)
    siblingCollectionChild = new Node(@root)


    parent.attach(siblingNode)
    parent.attach(siblingCollection)
    siblingCollection.attach(siblingCollectionChild)
    parent.attach(@node)

    assert.equal @node.previousSibling(), siblingCollection, "Must return previous collection"
    assert.equal @node.previousSibling().previousSibling(), siblingNode, "Must return previous node"
    assert.equal @node.previousSibling().previousSibling().previousSibling(), null, "Must return null"

QUnit.test "Node.previousWithTest()", (assert)->
    parent = new NodeCollection(@root)
    previousNode = new NodeCollection(@root)
    previousNodeChild = new Node(@root)

    parent.attach(previousNode)
    parent.attach(previousNodeChild)
    parent.attach(@node)

    previousNodeChild.testFlag = true

    assert.equal @node.previousWithTest((node)-> node.testFlag), previousNodeChild, "should return the previous node in the tree that matches"
    assert.equal @node.previousWithTest((node)-> false), null, "should return null"

QUnit.test "Node.fromDOMElement()", (assert)->
    assert.throws Node.fromDOMElement, /`fromDOMElement` not implemented/, "should be abstract class method"
