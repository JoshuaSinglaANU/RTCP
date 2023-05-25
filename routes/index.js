var express = require('express');
var router = express.Router();

router.get('/', function(req, res) {
    // Render the 'index' jade file

    session = req.session;

    if (req.session.userid) {
      res.render("index");
    } else {
      res.redirect("/login");
    }

})

module.exports = router;