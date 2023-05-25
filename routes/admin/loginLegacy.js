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
const SESSION_IDS = {};


// variable for the difficulty of breaking the login
var difficulty = 3;

// variable to all URL re-writing
var URLRewrite = false;

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
  admin: {
    type: DataTypes.INTEGER
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

    session = req.session;
    console.log(req.session.userid);


    if (req.session.userid) {
      console.log("Already logged in");
      res.redirect("/");
    } else {
      console.log("Not logged in");
      res.render('login');
    }

})

// Once the login form is posted, run this
router.post('/', async function (req, res) {

      if (difficulty == 0) {
        var query = "SELECT * FROM user WHERE username = '" +  req.body.username + "' AND password = '" + req.body.password + "'"
        const [results, metadata] = await sequelize.query(query);

        if (results.length >= 1) {
          console.log(results);
          var admin = results[0].admin;
          req.session.admin = admin;
          req.session.userid = req.body.username;
          if (URLRewrite) {
            res.redirect('/?sessionID=' + req.sessionID);
          } else {
            res.redirect('/');
          }    
        } else {
          res.render('login', {username: req.body.username, password: req.body.password, outcome: 'fail'});
        }
      } else if (difficulty == 1) {
          queryResult = await User.findAll({
            where: {
                username: req.body.username,
                password: req.body.password
            }
        })  
        if (queryResult.length == 1) {
            var admin = queryResult[0].dataValues.admin;
            req.session.admin = admin;
            req.session.userid = req.body.username;
            if (URLRewrite) {
              res.redirect('/?sessionID=' + req.sessionID);
            } else {
              res.redirect('/');
            } 
        } else if (queryResult.length == 0) {
            res.render('login', {username: req.body.username, password: req.body.password, outcome: 'fail'});
        } else {
            // render the error page
            res.render('error500');
        } 
      } else if (difficulty == 2) {
          // Query the server and check that the username/password pair exists
          queryResult = await User.findAll({
            where: {
                username: req.body.username,
                password: cipherRot13(req.body.password)
            }
        })  
        if (queryResult.length == 1) {
            var admin = queryResult[0].dataValues.admin;
            req.session.admin = admin;
            req.session.userid = req.body.username;
            if (URLRewrite) {
              res.redirect('/?sessionID=' + req.sessionID);
            } else {
              res.redirect('/');
            }
        } else if (queryResult.length == 0) {
            res.render('login', {username: req.body.username, password: req.body.password, outcome: 'fail'});
        } else {
            // render the error page
            res.render('error500');
        }          
       
      } else if (difficulty == 3) {
          console.log("authenticating");
          queryResult = await User.findAll({
            where: {
                username: req.body.username,
            }
        })      
          if (queryResult.length == 1) {
            var password = queryResult[0].dataValues.password;
            var admin = queryResult[0].dataValues.admin;
            console.log(admin);
            bcrypt.compare(req.body.password, password, function (err, result) {
              if (result) {  
                req.session.userid = req.body.username;
                req.session.admin = admin;
                if (URLRewrite) {
                  res.redirect('/?sessionID=' + req.sessionID);
                } else {
                  res.redirect('/');
                }   
              } else {
                res.render('login', {username: req.body.username, password: req.body.password, outcome: 'fail'});           
              }
            }); 
        } else if (queryResult.length == 0) {
          deny()
        } else {
            // render the error page
            res.render('error500');
        }        
      } else if (difficulty == 4) {
      console.log("Heighest difficulty")  
      var T = 10000;
      N = 1;
      lockOutList = lockOutList.filter(filterLockOutList);

      console.log("Filtered lockout list");
      console.log(lockOutList);

      var attempts = new Map();
      var cookieVariables
      var validate;
    if (req.cookies["DEVICE"] != undefined) {
      cookieVariables = req.cookies["DEVICE"];
      console.log("DEVICE: " + req.cookies["DEVICE"]);
      console.log("Username: " + req.body.username);
      validate = ((req.cookies["DEVICE"]) === req.body.username);
    } else {
      res.cookie("DEVICE", req.body.username);
      validate = false;
    }
    console.log(req.cookies["DEVICE"]);

    
    if (validate) {
      if (checkCookie(req.cookies["DEVICE"])) {
        deny();
        return;
      }
    }

    authenticate();


    function checkCookie (cookie) {
      for (let i = 0; i < lockOutList.length; i++) {
        var ll = lockOutList[i];
        if (ll[0] == cookie) {
          return true;
        }
      }
    }

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
        var admin = queryResult[0].dataValues.admin;
        console.log(admin);
        bcrypt.compare(req.body.password, password, function (err, result) {
          if (result) {


            res.cookie("DEVICE", req.body.username);
            req.session.userid = req.body.username;
            req.session.admin = admin;
            if (URLRewrite) {
              res.redirect('/?sessionID=' + req.sessionID);
            } else {
              res.redirect('/');
            }    
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

    function filterLockOutList(ll) {
      return (Date.now() - ll[1]) < T;
    }

    function deny () {
      console.log("username password wrong");
          log.push([req.body.username, Date.now(), req.cookies["DEVICE"]])
          log = log.filter(checkTime);
          console.log(lockOutList);
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
              lockOutList.push([req.cookies["DEVICE"], Date.now()]);
              res.render('login', {username: req.body.username, password: req.body.password, outcome: 'locked out'});
              return; 
            }
          } else {
              for (let i = 0; i < log.length; i++) {
                var l = log[i];
                if (l[0] === req.body.username && (Date.now() - l[1]) <= T) {
                  count++;
                }

                if (count > N) {
                  lockOutList.push([req.cookies["DEVICE"], Date.now()]);
                  res.render('login', {username: req.body.username, password: req.body.password, outcome: 'locked out'});
                  return; 
                }
              }
          }

          res.render('login', {username: req.body.username, password: req.body.password, outcome: 'incorrect username/password'});

    }
}
}
)

function cipherRot13(str) {
  str = str.toUpperCase();
  return str.replace(/[A-Z]/g, rot13);

  function rot13(correspondance) {
    const charCode = correspondance.charCodeAt();
    return String.fromCharCode(
            ((charCode + 13) <= 90) ? charCode + 13
                                    : (charCode + 13) % 90 + 64
           );
    
  }
}

module.exports = router;


