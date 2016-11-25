QUnit = require("qunitjs")
sinon = require("sinon")
Root = require("./root.coffee")
Node = require("./node.coffee")
NodeCollection = require("./node_collection.coffee")

QUnit.module "press.dom.NodeCollection",
    beforeEach: ->
        @root = new Root()
        @nodeCollection = new NodeCollection(@root)

QUnit.test "NodeCollection.root", (assert)->
    assert.equal @nodeCollection.root, @root, "@root should exists"

QUnit.test "NodeCollection.descendants()", (assert)->
    childNode = new Node(@root)

    childCollection = new NodeCollection(@root)
    childCollectionChildNode = new Node(@root)

    @nodeCollection.attach(childNode)
    @nodeCollection.attach(childCollection)
    childCollection.attach(childCollectionChildNode)

    assert.deepEqual @nodeCollection.descendants(), [
        childNode,
        childCollection,
        childCollectionChildNode
    ], "should return list of all descendants"

QUnit.test "NodeCollection.type()", (assert)->
    assert.equal @nodeCollection.type(), "NodeCollection", "expect `NodeCollection` type"

QUnit.test "NodeCollection.attach()", (assert)->
    node = new Node(@root)
    @nodeCollection.attach(node)

    assert.equal @nodeCollection.children[0], node, "should attach node to nodeCollection"

    node2 = new Node(@root)
    node3 = new Node(@root)

    @nodeCollection.attach(node2)
    @nodeCollection.attach(node3)

    newNode2 = new Node(@root)
    @nodeCollection.attach(newNode2, 1)

    assert.equal @nodeCollection.children[1], newNode2, "should attach node to nodeCollection at specified index"

    spy = sinon.spy()
    @root.bind("attach", spy)

    newNode = new Node(@root)
    @nodeCollection.attach(newNode)

    assert.ok spy.calledWith(@nodeCollection, newNode), "should trigger attach event on root"

QUnit.test "NodeCollection.commit()", (assert)->
    childCollection = new NodeCollection(@root)
    childNode = new Node(@root)

    @nodeCollection.attach(childCollection)
    childCollection.attach(childNode)

    childNode.taint()
    assert.notEqual childNode.lastModified(), null, "should set `not null` value to lastModified after node.taint()"

    childNode.commit()
    assert.equal childNode.lastModified(), null, "should set `null` value to lastModified after node.commit()"

    spy = sinon.spy()
    @root.bind("commit", spy)

    childCollection.commit()
    assert.ok spy.calledWith(childCollection), "should trigger commit event on root"

QUnit.test "NodeCollection.detach()", (assert)->
    node = new Node(@root)
    @nodeCollection.attach(node)

    @nodeCollection.detach(node)
    assert.equal @nodeCollection.children.length, 0, "should detach node from nodeCollection"
    assert.equal node.parent(), null, "should set null to node parent"

    @nodeCollection.attach(node)

    spy = sinon.spy()
    @root.bind("detach", spy)

    @nodeCollection.detach(node)
    assert.ok spy.calledWith(@nodeCollection, node), "should trigger detach event on root"
