idCounter = 0;
module.exports = (prefix = '')->
    idCounter += 1
    id = idCounter;
    return prefix + id
