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

  // Create the model for the query
const User = sequelize.define('user', {
  username: {
    type: DataTypes.STRING,
    allowNull: false
  },
  password: {
    type: DataTypes.STRING
  },
  first_name: {
    type: DataTypes.STRING
  },
  last_name: {
    type: DataTypes.STRING
  }
}, {
  tableName: 'user',
  timestamps: false
});

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
    await User.create({username: req.body.username, password: req.body.password, first_name: req.body.firstName, last_name: req.body.surname});
    return;
})

module.exports = router;