var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "RTCPDatabase"
})

//Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))

const User = sequelize.define('User', {
  // Model attributes are defined here
  username: {
    type: DataTypes.STRING,
    allowNull: false
  },
  password: {
    type: DataTypes.STRING
    // allowNull defaults to true
  }
});

console.log(User === sequelize.models.User);

const bodyParser = require('body-parser');

router.use(bodyParser.urlencoded({ extended: true }));

/* GET users listing. */
router.get('/', function(req, res) {

    res.render('index');
})

router.post('/', async function (req, res) {
    console.log(req.body);
    result = await User.count({
        where: {
            username: req.body.username,
            password: req.body.password,
        }
    })
    console.log("Result: " + result);

    if (result == 1) {
        res.render('index', {username: req.body.username, password: req.body.password, outcome: 'success'});
    } else if (result == 0) {
        res.render('index', {username: req.body.username, password: req.body.password, outcome: 'fail'});
    } else {
          // render the error page
        res.render('error500');
    }
})

module.exports = router;


