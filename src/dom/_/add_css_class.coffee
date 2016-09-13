module.exports = (domElement, className) ->
    # Add a CSS class to a DOM element

    # Add the class using classList if possible
    if domElement.classList
        domElement.classList.add(className)
        return

    # As there isn't universal support for the classList attribute, fallback
    # to a more manual process if necessary.
    classAttr = domElement.getAttribute('class')
    if classAttr
        # Convert class attribute to a list of class names
        classNames = (c for c in classAttr.split(' '))

        # If the class name isn't in the list add it
        if classNames.indexOf(className) == -1
            domElement.setAttribute(
                'class',
                "#{ classAttr } #{ className }"
                )

    else
        domElement.setAttribute('class', className)
