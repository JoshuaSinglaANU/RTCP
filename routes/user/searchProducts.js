// Boilerplate. Importing all of the frameworks.
var express = require('express');
var router = express.Router();
var session;
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

// Variable for the SQL injection difficulty
var obj = require('../../config.json');
const SQLInjectionDifficulty = obj.vulnerabilities[0].SQL_Injection

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})


/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    console.log("Rendering file");
    // res.sendFile('searchProducts.html', { root: "views" });
    res.render("searchProducts.jade", {
        rows: []
    });
})

router.get('/search', async function(req, res) {

    if (SQLInjectionDifficulty == 1) {
    var query = "SELECT * FROM product WHERE name = '" + req.query.pname + "' AND released = 1"
    // var query = "SELECT * FROM product WHERE released = 1 AND name = '" + req.query.pname + "'";
    // Unreleased'-- (make sure that some product is actually unreleased)

    try {
    const [results, metadata] = await sequelize.query(query);
    res.render("searchProducts.jade", {
        rows : results
    });
    } catch (error) {
        console.log(error)
        res.redirect("back");
    };


    } else if (SQLInjectionDifficulty == 2) {

    // Get Data from another table
    // Step 1
    // ' UNION SELECT type, name, tbl_name FROM sqlite_master --'

    // Step 2
    // ' UNION SELECT username, password, password FROM user --'   

    // solution
    // ' UNION SELECT username, password, password FROM user --

    try {
    var query = "SELECT name, price, quantity FROM product WHERE released = 1 AND name = '" + req.query.pname + "'";
    const [results, metadata] = await sequelize.query(query);
    res.render("searchProducts.jade", {
        rows : results
    });
    } catch (error) {

    }
    } else if (SQLInjectionDifficulty == 3) {
        // blind SQL injection. Very difficult to solve this task.
        try {
            // ' AND (SELECT CASE WHEN (1=2) THEN 1/0 ELSE 'a' END)='a
            var query = "SELECT name, price, quantity FROM product WHERE released = 1 AND name = '" + req.query.pname + "'";
            const [results, metadata] = await sequelize.query(query);
            res.render("searchProducts.jade", {
                rows : results
            });
            } catch (error) {
                
    }
    }
  });


module.exports = router;