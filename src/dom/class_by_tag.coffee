cache = {}

classByTag = (tagName)->
    unless cache[tagName]
        throw new Error("Unexpect tagName '#{tagName}'")
    return cache[tagName]

classByTag.associate = (classInstance, tagNames)->
    for tagName in tagNames
        if cache[tagName]
            throw new Error("TagName `#{tagName}` already associated with `#{cache[tagName].type()}`.\nYou try associate with `#{classInstance.type()}`.")

module.exports = classByTag
