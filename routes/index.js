// Boilerplate. Importing all of the frameworks.
var express = require('express');
var router = express.Router();
var session;
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

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
  tableName: 'user'
});

// Convert POST requests to JSON data
const bodyParser = require('body-parser');
router.use(bodyParser.urlencoded({ extended: true }));

/* GET users listing. */
router.get('/', function(req, res) {
    // Render the 'index' jade file
    res.render('index');
})

// Once the login form is posted, run this
router.post('/', async function (req, res) {
    console.log(req.body);

    // Query the server and check that the username/password pair exists
    result = await User.count({
        where: {
            username: req.body.username,
            password: req.body.password,
        }
    })
    console.log("Result: " + result);
    res.cookie('session', req.body.username);
    // Response once the query has been run
    if (result == 1) {
        res.render('index', {username: req.body.username, password: req.body.password, outcome: 'success'});
        console.log("Session");
        session = req.session;
        session.userid = req.body.username;
        console.log(req.session);
        

    } else if (result == 0) {
        res.render('index', {username: req.body.username, password: req.body.password, outcome: 'fail'});
    } else {
        // render the error page
        res.render('error500');
    }
})

module.exports = router;


