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

const UserAddress = sequelize.define('user_address', {
    address: {
      type: DataTypes.STRING,
    },
    city: {
      type: DataTypes.STRING
    },
    country: {
      type: DataTypes.STRING
    },
    mobile: {
      type: DataTypes.INTEGER
    }
  }, {
    tableName: 'user_address',
    timestamps: false
  });

  const UserPayment = sequelize.define('user_payment', {
    provider: {
      type: DataTypes.STRING,
    },
    account_no: {
      type: DataTypes.STRING
    }
  }, {
    tableName: 'user_payment',
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
    await UserAddress.create({address: req.body.address, city: req.body.city, country: req.body.country, mobile: req.body.mobile});
    await UserPayment.create({provider: req.body.paymentProvider, account_no: req.body.accountNumber});
    return;
})

module.exports = router;