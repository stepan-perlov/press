module.exports = (domElement, className) ->
    # Remove a CSS class from a DOM element

    # Remove the class using classList if possible
    if domElement.classList
        domElement.classList.remove(className)

        if domElement.classList.length == 0
            domElement.removeAttribute('class')

        return

    # As there isn't universal support for the classList attribute, fallback
    # to a more manual process if necessary.
    classAttr = domElement.getAttribute('class')

    if classAttr
        # Convert class attribute to a list of class names
        classNames = (c for c in classAttr.split(' '))

        # If the class name is in the list remove it
        classNameIndex = classNames.indexOf(className)
        if classNameIndex > -1
            classNames.splice(classNameIndex, 1)

            if classNames.length
                domElement.setAttribute(
                    'class',
                    classNames.join(' ')
                    )
            else
                domElement.removeAttribute('class')
