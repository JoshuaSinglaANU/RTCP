var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res) {
    // Render the 'index' jade file
    if (req.session.userid) {
        res.render('profile');
    } else {
        console.log("not logged in");
        res.redirect('/');
    }
})

module.exports = router;