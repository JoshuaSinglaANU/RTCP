var S = require('pull-stream/pull')

// take an array of objects of streams
// `pull` them all together based on their keys
function pipe (demuxedStreams) {
    var dxStreams = Array.isArray(demuxedStreams) ?
        demuxedStreams :
        Array.prototype.slice.call(arguments)
    var source = dxStreams[0]
    var sinks = dxStreams.slice(1)
    var keys = Object.keys(source)
    var sinksByKey = keys.reduce(function (acc, k) {
        acc[k] = sinks
            .map(function (sink) {
                return sink[k]
            })
            .filter(Boolean)
        return acc
    }, {})

    var newDxStream = keys.reduce(function (acc, k) {
        var _source = source[k]
        var lastSink = sinksByKey[k][sinksByKey[k].length - 1]
        if (!lastSink) {
            throw new Error('Stream ' + k + ' does not have a sink')
        }
        acc[k] = S.apply(null, [_source].concat(sinksByKey[k]))
        return acc
    }, {})
    return newDxStream
}

module.exports = pipe
