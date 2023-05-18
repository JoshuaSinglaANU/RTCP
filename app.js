const port = 40007

var createError = require('http-errors');
var express = require('express');
var bcrypt = require("bcrypt")
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var serveIndex = require('serve-index')
var csrf = require('csurf');

var loginRouter = require('./routes/login.js');
var profileRouter = require('./routes/user/profile.js')
var createAccountRouter = require('./routes/createAccount.js')
var indexRouter = require('./routes/index.js')
var usersRouter = require('./routes/admin/users.js')
var searchProductsRouter = require('./routes/user/searchProducts.js')
var directoryRouter = require('./routes/admin/directory.js')
var answerRouter = require('./routes/answer.js')
var updateProfileRouter = require('./routes/user/changeProfile.js')
var feedbackRouter = require('./routes/feedback.js')
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

  const Product = sequelize.define('product', {
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    price: {
      type: DataTypes.FLOAT,
      allowNull: false
    },
    quantity: {
      type: DataTypes.STRING,
      allowNull: true
    },
    released: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
  }, {
    tableName: 'product',
    timestamps: false
  });
  

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
  
  User.hasOne(UserAddress, { foreignKey: 'id' });
  UserAddress.belongsTo(User, { foreignKey: 'id' });
  
  User.hasOne(UserPayment, { foreignKey: 'id' });
  UserPayment.belongsTo(User, { foreignKey: 'id' });

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
app.set("answeredQuestions", false);
app.set('trust proxy', 1) // trust first proxy
const oneDay = 1000 * 60 * 60 * 24;
app.use(sessions({
  secret: "secret",
  resave: false,
  saveUninitialized: true,
  cookie: {
    httpOnly: false,
    generatedQuestions: false
  }
}));

const csrfProtection = csrf({ cookie: true });

// default options
app.use(fileUpload());
app.use('/login', loginRouter);

app.use('/', indexRouter);

app.use('/profile', profileRouter);

app.use('/feedback', feedbackRouter);

app.use('/createAccount', createAccountRouter);

app.use('/admin/users', usersRouter);

app.use('/answer', answerRouter);

app.use('/updateProfile', csrfProtection); 
app.use('/updateProfile', updateProfileRouter);

app.use('/searchProducts', searchProductsRouter);

// Enable CSRF protection for all routes except "/profile/update"

// app.use((req, res, next) => {
//   if (req.url === '/updateProfile') {
//     next();
//   } else {
//     csrf({ cookie: true })(req, res, next);
//   }
// });

var obj = require('./config.json');
const allowDirectoryListing = obj.vulnerabilities[0].Directory_Listing;
const encryptionLevel = obj.vulnerabilities[0].Authentication;


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


async function createQuestionsAndAnswers () {

  await populateUserAccounts ();


  var randomUser = await select_random_user();

  var numUnseleasedProducts = await count_unreleased_products ();

  var numUnseleasedProductsQuantity = await count_unreleased_products_quantity ();

  var mostExpensiveProduct = await getMostExpensiveProduct();

  var totalPrice = await getTotalPrice();

  var numUsers = await getNumUsers();

  var questions_and_solutions = {
    vulnerabilities: {
      SQL_Injection: {
        Difficulty: [
          [
            {
              question: `How many products are there in total?`,
              answer: `${randomUser.last_name}`
            },
            {
              question: `How many unreleased products are there?`,
              answer: `${numUnseleasedProducts}`
            },
            {
              question: `What is the total quantity of the unreleased products?`,
              answer: `${numUnseleasedProductsQuantity}`
            },
            {
              question: `What is the most expensive product?`,
              answer: `${mostExpensiveProduct}`
            },
            {
              question: `What is the total price of the inventory?`,
              answer: `${totalPrice}`
            }
          ],
          [
            {
              question: `How many total users are there?`,
              answer: `${numUsers}`
            },
            {
              question: `What is the password for the ${randomUser.username}, as stored in the server database?`,
              answer: `${randomUser.password}`
            },
            {
              question: `What is the street address of ${randomUser.username}?`,
              answer: `${randomUser.user_address.address}`
            },
            {
              question: `What is the mobile number of the admin?`,
              answer: `${randomUser.user_address.mobile}`
            },
            {
              question: `What is the city of the admin?`,
              answer: `${randomUser.user_address.city}`
            }
          ]
        ],
        URL_rewriting: [
          {
            question: `What is the current sessionID?`,
            answer: `${randomUser.last_name}`
          },
          {
            question: `What is the last name ${randomUser.first_name}`,
            answer: `${randomUser.last_name}`
          },
          {
            question: `What is the length of the current sessionID?`,
            answer: `${randomUser.last_name}`
          },
          {
            question: `How many numerals are there in the current sessionID?`,
            answer: `${randomUser.last_name}`
          }
        ]
      },
      Authentication: [
        {
          question: `What is the password for the admin user, as stored in the server database?`,
          answer: `${randomUser.last_name}`
        },
        {
          question: `What is the address of the admin?`,
          answer: `${randomUser.last_name}`
        },
        {
          question: `What is the provider number for the admin?`,
          answer: `${randomUser.last_name}`
        },
        {
          question: `What is the street address of the admin?`,
          answer: `${randomUser.last_name}`
        },
        {
          question: `What is the mobile number of the admin?`,
          answer: `${randomUser.last_name}`
        },
        {
          question: `What is the city of the admin?`,
          answer: `${randomUser.last_name}`
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
  // Delete all users from the database
  await UserAddress.destroy({
    where: {},
    truncate: true
  });
  console.log('User Address emptied.');
} catch (err) {
  console.error(err);
}

try {
  // Delete all users from the database
  await UserPayment.destroy({
    where: {},
    truncate: true
  });
  console.log('User Payment emptied.');
} catch (err) {
  console.error(err);
}




try {
  const numUsers = 10;
  const users = [];
  const userAddresses = [];
  const userPayments = [];
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
        passwordPromises.push(bcrypt.hash(password, 10));
        break;
      default:
        passwordPromises.push(bcrypt.hash(password, 10));
        break;
    }


    const first_name = Math.random().toString(36).substring(2, 8);
    const last_name = Math.random().toString(36).substring(2, 8);
    const admin = 0;
    const user = { username, password, first_name, last_name, admin };
    users.push(user);

    const address = Math.random().toString(36).substring(2, 8);
    const city = Math.random().toString(36).substring(2, 8);
    const country = Math.random().toString(36).substring(2, 8);
    const mobile = generateRandomNumber();
    const provider = Math.random().toString(36).substring(2, 8);
    const account_no = Math.random().toString(36).substring(2, 8);
    userAddresses.push({address, city, country, mobile});
    userPayments.push({provider, account_no});

  }
  console.log(userAddresses);
  const hashedPasswords = await Promise.all(passwordPromises);
  for (let i = 0; i < numUsers; i++) {
    const user = await User.create({ ...users[i], password: hashedPasswords[i] });
    await UserAddress.create(userAddresses[i]);
    await UserPayment.create(userPayments[i]);
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

async function select_random_user () {
  try {
    const count = await User.count();
    const randomIndex = Math.floor(Math.random() * count);
  
    console.log("Executing query!")
    const user = await User.findOne({
      offset: randomIndex,
      order: sequelize.random(),
      include: [
        { model: UserAddress },
        { model: UserPayment }
      ],
      raw: true,
      nest: true
    });
    console.log(user);
    return user;
    
  } catch (err) {
    console.error(err);
    throw err;
  }
}

async function count_unreleased_products () {
  return Product.count({
    where: {
      released: 0
    }
  })
    .then(count => {
      console.log("Num released products " + count)
      return count;
    })
    .catch(error => {
      console.error(`Error counting released products: ${error.message}`);
    });
}

async function count_unreleased_products_quantity () {
  return Product.sum('quantity', {
    where: {
      released: 0
    }
  })
    .then(total => {
      return total;
    })
    .catch(error => {
      console.error(`Error finding total quantity of unreleased products: ${error.message}`);
    });
}

async function getTotalPrice () {
  return Product.sum('quantity')
    .then(total => {
      return total;
    })
    .catch(error => {
      console.error(`Error finding total price of unreleased products: ${error.message}`);
    });
}

function getMostExpensiveProduct() {
  return Product.findOne({
    where: {
      price: {
        [Sequelize.Op.eq]: Sequelize.literal(`(SELECT MAX(price) FROM product)`)
      }
    }
  })
    .then(product => {
      return product.price;
    })
    .catch(error => {
      console.error(`Error finding most expensive product: ${error.message}`);
    });
}

async function getNumUsers () {
  return User.count()
    .then(count => {
      console.log("Num users " + count)
      return count;
    })
    .catch(error => {
      console.error(`Error counting num users: ${error.message}`);
    });
}
function generateRandomNumber() {
  const min = 1000000000;
  const max = 9999999999;
  return Math.floor(Math.random() * (max - min + 1) + min);
}

console.log(generateRandomNumber());

