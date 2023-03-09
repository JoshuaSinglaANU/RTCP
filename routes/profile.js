var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})






// // Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))






// Create the model for the user payment table
const UserPayment = sequelize.define('user_payment', {
  username: {
    type: DataTypes.STRING,
    allowNull: false
  },
  address: {
    type: DataTypes.STRING
  }
}, {
  tableName: 'user_payment'
});

// Create a model for the user table
const User = sequelize.define('user', {
  userid: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  username: {
    type: DataTypes.STRING
  }
}, {
  tableName: 'user'
});





/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    if (req.session.userid) {


        var query = "SELECT address, city, country, mobile FROM user, user_address WHERE user.id = user_address.id AND user.username = \"" + req.session.userid + "\"";
        const [results, metadata] = await sequelize.query(query)
        console.log(results)




        res.render('profile');
    } else {
        console.log("not logged in");
        res.redirect('/');
    }
})

module.exports = router;