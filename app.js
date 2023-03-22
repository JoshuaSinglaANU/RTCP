const port = 40001

var createError = require('http-errors');
var express = require('express');

var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');

var loginRouter = require('./routes/login.js');
var profileRouter = require('./routes/profile.js')
var createAccountRouter = require('./routes/createAccount.js')
var indexRouter = require('./routes/index.js')

var cookieSession = require('cookie-session')
var app = express();

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
app.use(express.static(path.join(__dirname, 'public')));

app.set('trust proxy', 1) // trust first proxy
const oneDay = 1000 * 60 * 60 * 24;
app.use(sessions(
  {secret: "Shh, its a secret!",
   resave: true,
   saveUninitialized: false,
   cookie: {
    expires: 60000
   }
  }))


app.use('/login', loginRouter);

app.use('/', indexRouter);

app.use('/profile', profileRouter);

app.use('/createAccount', createAccountRouter);



// app.use(cookieSession({
//   name: 'session',
//   sameSite: 'none',
//   keys: []
// }))

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

// Start the app
app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})