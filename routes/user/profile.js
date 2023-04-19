var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})

// variable to allow/disallow Insecure Direct Object References
var allowReference = 0;


// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))

/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file

    if (req.query.account == null) {
        if (req.session.userid) {
                res.redirect("/profile/?account=" + req.session.userid)
        } else {
            res.redirect("/");
        }
    } else {
        if (allowReference == 0) {
            if (req.session.userid == req.query.account) {
                var query = "SELECT * FROM user, user_address, user_payment WHERE user.id = user_address.id AND user.id = user_payment.id AND user.username = '" + req.session.userid + "'";
                const [results, metadata] = await sequelize.query(query, { type: QueryTypes.SELECT })
                console.log(results)
                res.render('user/profile', {username: req.session.userid, address: results.address, city: results.city, country: results.country, mobile: results.mobile, provider: results.provider, accountNumber: results.account_no});  
            } else {
                res.redirect("back");
            }
        } else if (allowReference == 1) {
            var query = "SELECT * FROM user, user_address, user_payment WHERE user.id = user_address.id AND user.id = user_payment.id AND user.username = '" + req.query.account+ "'";
            const [results, metadata] = await sequelize.query(query, { type: QueryTypes.SELECT })
            console.log(results)
            res.render('user/profile', {username: req.query.account, address: results.address, city: results.city, country: results.country, mobile: results.mobile, provider: results.provider, accountNumber: results.account_no});    
        }
    }
})

module.exports = router;