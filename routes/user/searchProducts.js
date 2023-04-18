// Boilerplate. Importing all of the frameworks.
var express = require('express');
var router = express.Router();
var session;
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPPDB"
})


/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    console.log("Rendering file");
    // res.sendFile('searchProducts.html', { root: "views" });
    res.render("searchProducts.ejs");
})

router.get('/search', async function(req, res) {
    var query = "SELECT * FROM product WHERE name = '" + req.query.pname + "' AND released = 1"
    console.log(query);
    const [results, metadata] = await sequelize.query(query);
    console.log(results);
    res.send(results);
  });


module.exports = router;