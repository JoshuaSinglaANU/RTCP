// take an object whos nodes are event busses
// return an array of strings or nested arrays

function toArray (obj) {
    var keys = Object.keys(obj)
    var arr = keys.map(function (k) {
        return toNode(k, obj[k])
    })
    return arr
}

function toNode (type, node) {
    return !Object.keys(node).length ?
        type :
        [type, toArray(node)]
}

module.exports = toArray

