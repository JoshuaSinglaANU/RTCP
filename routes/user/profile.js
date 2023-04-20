var express = require('express');
var router = express.Router();
const { dirname } = require('path');
const appDir = dirname(require.main.filename);
const multer  = require('multer')
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})

// variable to allow/disallow Insecure Direct Object References
var allowReference = 1;

var storage =   multer.diskStorage({  
    destination: function (req, file, callback) {  
      callback(null, __dirname + "/public/images");  
    },  
    filename: function (req, file, callback) {  
      callback(null, file.originalname);  
    }  
});  
var upload = multer({ storage : storage}).single('avatar');   
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


// router.get('/updateAvatar', async function(req, res) {
//     console.log(req);
//     upload(req,res,function(err) {  
//         if(err) {  
//             return res.end("Error uploading file.");  
//         }  
//         res.end("File is uploaded successfully!");  
//     });  
//     return;
// });

router.post('/updateAvatar', function(req, res) {
    if (!req.files || Object.keys(req.files).length === 0) {
      return res.status(400).send('No files were uploaded.');
    }
  
    console.log(req.files["avatar"]);
    // The name of the input field (i.e. "sampleFile") is used to retrieve the uploaded file
    let sampleFile = req.files["file"];

    // Use the mv() method to place the file somewhere on your server
    console.log(__dirname + "/public/images/" + sampleFile.name);
    sampleFile.mv(appDir + "/public/images/" + sampleFile.name, function(err) {
      if (err)
        return res.status(500).send(err);
  
      res.send('File uploaded!');
    });
  });

module.exports = router;