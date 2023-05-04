const port = 40005

var createError = require('http-errors');
var express = require('express');
var bcrypt = require("bcrypt")
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var serveIndex = require('serve-index')

var loginRouter = require('./routes/login.js');
var profileRouter = require('./routes/user/profile.js')
var createAccountRouter = require('./routes/createAccount.js')
var indexRouter = require('./routes/index.js')
var usersRouter = require('./routes/admin/users.js')
var searchProductsRouter = require('./routes/user/searchProducts.js')
var directoryRouter = require('./routes/admin/directory.js')
var answerRouter = require('./routes/answer.js')
var updateProfileRouter = require('./routes/user/changeProfile.js')
const fs = require('fs')
const https = require('https');
const { Sequelize, DataTypes } = require('sequelize');

var app = express();
var fileUpload = require('express-fileupload');
var sessions = require('express-session')

const sequelize = new Sequelize({
  dialect: "sqlite",
  storage: "databases/RTCPUDB"
})

// Test the DB Connection
sequelize.authenticate()
  .then(() => console.log('Database Connected'))
  .catch(err => console.log('Error: ', err))


createQuestionsAndAnswers ();

// view engine setup
// Assigning the name 'views' to everything under /views
app.set('views', path.join(__dirname, 'views'));

// Assigning the name name 'view engine' to 'jade'
app.set('view engine', 'jade');

// Setting up some admin stuff.
app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

app.set("generatedQuestions", false);
app.set('trust proxy', 1) // trust first proxy
const oneDay = 1000 * 60 * 60 * 24;
app.use(sessions({
  secret: "secret",
  resave: false,
  saveUninitialized: true,
  cookie: {
    httpOnly: false,
    expires: 60000,
    generatedQuestions: false
  }
}));



// default options
app.use(fileUpload());
app.use('/login', loginRouter);

app.use('/', indexRouter);

app.use('/profile', profileRouter);

app.use('/createAccount', createAccountRouter);

app.use('/admin/users', usersRouter);

app.use('/answer', answerRouter);

app.use('/updateProfile', updateProfileRouter);

app.use('/searchProducts', searchProductsRouter);

var obj = require('./config.json');
const allowDirectoryListing = obj.vulnerabilities[0].Directory_Listing;
const encryptionLevel = obj.vulnerabilities[0].Authentication;
populateUserAccounts ();

if (allowDirectoryListing) {
  app.use('/admin/directory', express.static(__dirname + "/"), serveIndex(__dirname + "/public", {'icons': true}))
} else {
  app.use('/admin/directory', loginRouter)
}

app.use('/public', express.static(__dirname + '/public'));
app.use(express.static(__dirname + '/public'));


// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error500');
});



module.exports = app;

const ifHttps = obj.vulnerabilities[0].SSL;

if (ifHttps) {
  const options = {
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem'),
    passphrase: '123456'
  };

  // Start HTTPS server
  https.createServer(options, app).listen(port, () => {
    console.log(`Example app listening on port ${port}`)
  });
} else {
  // Start the app
  app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
  })
}

function createQuestionsAndAnswers () {

  var questions_and_solutions = {
    vulnerabilities: {
      SQL_Injection: {
        Difficulty: [
          {
            question: "How many products are there in total?",
            answer: ""
          },
          {
            question: "How many unreleased products are there?",
            answer: ""
          },
          {
            question: "What is the total quantity of the unreleased products?",
            answer: ""
          },
          {
            question: "What is the most expensive product?",
            answer: ""
          },
          {
            question: "What is the total price of the inventory?",
            answer: ""
          }
        ],
        URL_rewriting: [
          {
            question: "What is the current sessionID?",
            answer: ""
          },
          {
            question: "What is the length of the current sessionID?",
            answer: ""
          },
          {
            question: "How many numerals are there in the current sessionID?",
            answer: ""
          }
        ]
      },
      Authentication: [
        {
          question: "What is the password for the admin user, as stored in the server database?",
          answer: ""
        },
        {
          question: "What is the address of the admin?",
          answer: ""
        },
        {
          question: "What is the provider number for the admin?",
          answer: ""
        },
        {
          question: "What is the street address of the admin?",
          answer: ""
        },
        {
          question: "What is the mobile number of the admin?",
          answer: ""
        },
        {
          question: "What is the city of the admin?",
          answer: ""
        }
      ]
    }
  };

  
  const json = JSON.stringify(questions_and_solutions, null, 2);

  fs.writeFile('questions.json', json, (err) => {
    if (err) {
      console.error(err);
      return;
    }
    console.log('JSON data has been written to file');
  });
  
}

async function populateUserAccounts () {
  // Define the User model
const User = sequelize.define('user', {
  username: {
    type: Sequelize.STRING,
    allowNull: false
  },
  password: {
    type: Sequelize.STRING,
    allowNull: false
  },
  first_name: {
    type: Sequelize.STRING,
    allowNull: false
  },
  last_name: {
    type: Sequelize.STRING,
    allowNull: false
  },
  admin: {
    type: Sequelize.INTEGER,
    allowNull: false
  }
}, {
  tableName: 'user',
  timestamps: false
});

try {
  // Delete all users from the database
  await User.destroy({
    where: {},
    truncate: true
  });
  console.log('User table emptied.');
} catch (err) {
  console.error(err);
}



try {
  const numUsers = 10;
  const users = [];
  const passwordPromises = [];
  for (let i = 0; i < numUsers; i++) {
    const username = Math.random().toString(36).substring(2, 8);
    const password = Math.random().toString(36).substring(2, 8);
    switch (encryptionLevel) {
      case 0:
        passwordPromises.push(Promise.resolve(password));
        break;
      case 1:
        passwordPromises.push(Promise.resolve(password));
        break;
      case 2:
        passwordPromises.push(Promise.resolve(cipherRot13(password)));
        break;
      case 3:
      default:
        passwordPromises.push(bcrypt.hash(password, 10));
        break;
    }
    const first_name = Math.random().toString(36).substring(2, 8);
    const last_name = Math.random().toString(36).substring(2, 8);
    const admin = 0;
    const user = { username, password, first_name, last_name, admin };
    users.push(user);
  }
  const hashedPasswords = await Promise.all(passwordPromises);
  for (let i = 0; i < numUsers; i++) {
    const user = await User.create({ ...users[i], password: hashedPasswords[i] });
    users[i] = user;
  }
} catch (err) {
  console.error(err);
}



}

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