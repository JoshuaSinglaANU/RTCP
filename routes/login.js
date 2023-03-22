// Boilerplate. Importing all of the frameworks.
var express = require('express');
var router = express.Router();
var session;
var bcrypt = require("bcrypt")
var crypto = require("crypto")
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

var lockOutList = [];
var log = [];

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
  }
}, {
  tableName: 'user',
  timestamps: false,
});

// Convert POST requests to JSON data
const bodyParser = require('body-parser');
router.use(bodyParser.urlencoded({ extended: true }));

/* GET users listing. */
router.get('/', function(req, res) {
    // Render the 'index' jade file
    res.render('login');

    session = req.session;
    console.log(req.session.userid);


    if (req.session.userid) {
      console.log("Already logged in");
    } else {
      console.log("Not logged in");
    }

})

// Once the login form is posted, run this
router.post('/', async function (req, res) {
      var T = 60000;
      N = 5;

      var attempts = new Map();
      var cookieVariables
      var validate;
    if (req.cookies["DEVICE"] != undefined) {
      cookieVariables = req.cookies["DEVICE"];
      validate = ((res.cookie["DEVICE"]) == req.body.username);
    } else {
      res.cookie("DEVICE", req.body.username);
      validate = true;
    }
    console.log(req.cookies);

    console.log(validate);
    if (validate) {
      if (lockOutList.includes(req.cookies["DEVICE"])) {
        console.log("includes device");
          res.render('login', {username: req.body.username, password: req.body.password, outcome: 'username incorrect'});
      }
    }

    authenticate();



    async function authenticate () {
    // Query the server and check that the username/password pair exists
    console.log("authenticating");
      queryResult = await User.findAll({
        where: {
            username: req.body.username,
        }
    })      
      if (queryResult.length == 1) {
        var password = queryResult[0].dataValues.password;
        // console.log("password: +" + password);
        bcrypt.compare(req.body.password, password, function (err, result) {
          if (result) {
            res.cookie("DEVICE", req.body.username);
            req.session.userid = req.body.username;
            res.redirect('/?sessionID=' + req.sessionID);    
          } else {
            deny()            
          }
        }); 
    } else if (queryResult.length == 0) {
      deny()
    } else {
        // render the error page
        res.render('error500');
    }
    }

    function checkTime(l) {
      return (Date.now() - l[1]) < T;
    }

    function deny () {
      console.log("username password wrong");
          log.push([req.body.username, Date.now(), req.cookies["DEVICE"]])
          log.filter(checkTime);
          console.log(log);
          var count = 0;
          if (req.cookies["DEVICE"] != undefined) {
            for (let i = 0; i < log.length; i++) {
              var l = log[i];
              if (l[0] === req.body.username && l[2] === req.cookies["DEVICE"] && (Date.now()- l[1]) <= T) {
                count++;
              }
            }
            console.log(count);
            if (count > N) {
              lockOutList.push(req.cookies["DEVICE"]);
            }
          } else {
              for (let i = 0; i < log.length; i++) {
                var l = log[i];
                if (l[0] === req.body.username && (Date.now() - l[1]) <= T) {
                  count++;
                }
              }
          }

          res.render('login', {username: req.body.username, password: req.body.password, outcome: 'incorrect'}); 
    }
})

module.exports = router;


