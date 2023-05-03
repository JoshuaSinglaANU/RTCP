const port = 40005

var createError = require('http-errors');
var express = require('express');

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

var app = express();
var fileUpload = require('express-fileupload');
var sessions = require('express-session')



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