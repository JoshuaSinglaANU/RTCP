var express = require('express');
var router = express.Router();

var serveIndex = require('serve-index');
router.use(express.static(__dirname + "/"))
router.use('/admin', serveIndex(__dirname + '/videos'));

module.exports = router;