var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})

// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))


  /* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    res.render("createAccount");
})

// Once the login form is posted, run this
router.post('/', async function (req, res) {
    return;
})

module.exports = router;