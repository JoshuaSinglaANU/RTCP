var express = require('express');
var router = express.Router();
const cookieParser = require('cookie-parser');
const xss = require('xss');

const difficulty = 1

router.get('/', function(req, res) {
    res.cookie('sessionid', {
         httpOnly: false 
        });
    // console.log(document.cookie);
    res.render("user/updateProfile");

})

{/* <script>
  const sessionId = document.cookie.split(';')[0].split('=')[1];
  alert(`Your session ID is: ${sessionId}`);
</script> */}

router.post('/', function(req, res) {

    switch (difficulty) {
        case 1: {
            var input = req.body.username;
            console.log(req.body);
            res.send('You submitted: ' + input);
        }
        break;
        case 2: {
            app.use((req, res, next) => {
                res.setHeader('Content-Security-Policy', "default-src 'self'");
                next();
              });
            var input = req.body.username;
            console.log(req.body);
            res.send('You submitted: ' + input);
        }
        break;
        case 3: {
            var input = xss(req.body.username);
            console.log(req.body);
            res.send('You submitted: ' + input);
        }
    }

})



module.exports = router;