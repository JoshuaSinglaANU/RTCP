var express = require('express');
var router = express.Router();
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes, QueryTypes } = require('sequelize');

// Metadata for the user database
const sequelize = new Sequelize({
    dialect: "sqlite",
    storage: "databases/RTCPUDB"
})

  // Create the model for the query
  const Message = sequelize.define('messages', {

    username: {
      type: DataTypes.STRING,
      allowNull: false
    },
    password: {
      type: DataTypes.STRING
    }
  }, {
    tableName: 'messages'
  });

// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))

  router.get('/messages', async function(req, res) {
    console.log("Getting messages");
    
    // var query = "SELECT user.username, message FROM messages, user WHERE user.id = messages.id AND user.username = 'jim'"
    var query = "SELECT * FROM `messages`"
    const [results, metadata] = await sequelize.query(query)
    console.log(results);
    res.send(results);
  
  })

/* GET users listing. */
router.get('/', async function(req, res) {
    // Render the 'index' jade file
    console.log("Rendering file");
    res.sendFile('chat.html', { root: "views" });
})


module.exports = router;
