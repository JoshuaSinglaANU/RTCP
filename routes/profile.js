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

/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    if (req.session.userid) {


        var query = "SELECT * FROM user, user_address, user_payment WHERE user.id = user_address.id AND user.id = user_payment.id AND user.username = \"" + req.session.userid + "\"";
        const [results, metadata] = await sequelize.query(query, { type: QueryTypes.SELECT })
        console.log(results)
        res.render('profile', {username: req.session.userid, address: results.address, city: results.city, country: results.country, mobile: results.mobile, provider: results.provider, accountNumber: results.account_no});    
    } else {
        console.log("not logged in");
        res.redirect('/');
    }
})

module.exports = router;