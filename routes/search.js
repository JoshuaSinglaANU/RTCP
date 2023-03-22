var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    res.sendFile('search.html', { root: "views" });
})

module.exports = router;