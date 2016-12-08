HtmlString = require("../../html_string/html_string")

module.exports = (attributes) ->
    # Convert a dictionary of attributes into a string (e.g key="value")
    unless attributes
        return ''

    # Sort the attributes alphabetically
    names = (name for name of attributes)
    names.sort()

    # Convert each key, value into an attribute string
    attributeStrings = []
    for name in names
        value = attributes[name]
        if value is ''
            attributeStrings.push(name)
        else
            # Escape the contents of the attribute
            value = HtmlString.encode(value)

            # We also need to escape quotes (") as the value will
            # sit within quotes.
            value = value.replace(/"/g, '&quot;')

            attributeStrings.push("#{ name }=\"#{ value }\"")

    return attributeStrings.join(' ')
