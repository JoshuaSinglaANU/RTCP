var express = require('express');
var router = express.Router();
var bcrypt = require("bcrypt")
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})

var hashStrength = 3;

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

function hashPassword (plaintextPassword) {
  bcrypt.hash(plaintextPassword, 10).then
}
  
  /* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    res.render("createAccount");
})

// Once the login form is posted, run this
router.post('/', async function (req, res) {
  if (hashStrength == 1) {
    await User.create({username: req.body.username, password:  req.body.password, first_name: req.body.firstName, last_name: req.body.surname, admin: 0});
  } else if (hashStrength == 2) {
    await User.create({username: req.body.username, password:  cipherRot13(req.body.password), first_name: req.body.firstName, last_name: req.body.surname, admin: 0});
  } else if (hashStrength == 3) {
    bcrypt.hash(req.body.password, 10).then(async hash => {
        await User.create({username: req.body.username, password: hash, first_name: req.body.firstName, last_name: req.body.surname, admin: 0});
    })
  }
    await UserAddress.create({address: req.body.address, city: req.body.city, country: req.body.country, mobile: req.body.mobile});
    await UserPayment.create({provider: req.body.paymentProvider, account_no: req.body.accountNumber});
    return;
})

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