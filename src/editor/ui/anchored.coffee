View = require("./view")

class Anchored extends View

    # Anchored components are mounted against a specified DOM element at a
    # specified anchor. Remounting an anchored component requires that the
    # parent perform the re-mount.
    #
    # The benefit of anchored components is they are light weight and can be
    # rendered into different a specific DOM element by the parent, for example
    # tools within the toolbox are anchored components.

    mount: (domParent, before=null) ->
        # Mount the component to the DOM (mount should be called by inheriting
        # classes after they've created their DOM element using `super`.

        # Mount the element
        domParent.insertBefore(@_domElement, before)

        # Add interaction handlers
        @_addDOMEventListeners()

module.exports = Anchored
