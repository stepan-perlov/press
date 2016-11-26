cache = {}

classByTag = (tagName)->
    tagName = tagName.toLowerCase()
    unless cache[tagName]
        throw new Error("Unexpect tagName '#{tagName}'")
    return cache[tagName]

classByTag.associate = (classInstance, tagNames)->
    for tagName in tagNames
        if cache[tagName]
            throw new Error("TagName `#{tagName}` already associated with `#{cache[tagName].type()}`.\nYou try associate with `#{classInstance.type()}`.")
        else
            cache[tagName] = classInstance

module.exports = classByTag
