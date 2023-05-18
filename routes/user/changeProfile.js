var express = require('express');
var router = express.Router();
const cookieParser = require('cookie-parser');
const xss = require('xss');

const difficulty = 1

router.get('/', function(req, res) {
    const isCSRFAttack = req.get('X-CSRF-Attack') === 'true';
    
    console.log("CSRF");
    console.log(isCSRFAttack);
    res.cookie('sessionid', {
         httpOnly: false 
        });
    // console.log(document.cookie);
    res.render("user/updateProfile", {csrfToken: req.csrfToken()});

})

{/* <script>
  const sessionId = document.cookie.split(';')[0].split('=')[1];
  alert(`Your session ID is: ${sessionId}`);
</script> */}

router.post('/', function(req, res) {

    const csrfToken = req.csrfToken();
    if (req.csrfToken() !== csrfToken) {
        res.status(403).send('CSRF token validation failed.');
        return;
      }


    console.log("CSRF");
    console.log(req.body);
    


    switch (difficulty) {
        case 1: {
            var input = req.body.username;
            console.log(req.body);
            res.send('You submitted: ' + input);
        }
        break;

        // Break this by tampering with URL
        case 2: {
            var input = req.body.username;
            console.log(req.body);
            res.setHeader('Content-Security-Policy', "default-src 'self'");
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

module.exports = router
