function Event (type, data) {
    return [type, data]
}
Event.type = function (ev) {
    return ev[0]
}
Event.data = function (ev) {
    return ev[1]
}

module.exports = Event

