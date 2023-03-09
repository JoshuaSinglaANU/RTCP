var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');
const { render } = require('../app');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPPD"
})

// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))

/* GET users listing. */
router.get('/', async function(req, res) {
    render(productSearch);
})

module.exports = router;