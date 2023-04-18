var express = require('express');
var router = express.Router();
var bcrypt = require("bcrypt")
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// variable to allow/disallow access
var allowAccess = 0;


// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})


// Create the model for the query
const User = sequelize.define('user', {

  username: {
    type: DataTypes.STRING,
    allowNull: false
  },
  password: {
    type: DataTypes.STRING
  }
}, {
  tableName: 'user',
  timestamps: false,
});

// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))

/* GET users listing. */
router.get('/', async function(req, res) {

  if (allowAccess == 1) {
    var users = await User.findAll({raw: true});
        res.render("admin/users", {
        rows: users
      });
  } else if (allowAccess = 0) {
    var users = await User.findAll({raw: true});
    console.log("ADMIN: " + req.session.admin);
    if (req.session.admin == 1) {
        res.render("admin/users", {
        rows: users
      });
    } else {
      res.redirect("/");
    }
  }
})

module.exports = router;  