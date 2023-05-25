var express = require('express');
var router = express.Router();

var serveIndex = require('serve-index');
router.use(express.static(__dirname + "/"))
router.use('/admin', serveIndex(__dirname + '/videos'));


router.get('/:file', async function(req, res) {
    var fileName = req.param.file;
    console.log("filename:" + fileName);
  })

module.exports = router;