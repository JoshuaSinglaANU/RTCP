var express = require('express');
var router = express.Router();
const bodyParser = require('body-parser');
const session = require('express-session');
var questions = [];
var answers = [];
router.use(bodyParser.json());

router.use(session({
  secret: 'my-secret-key',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false }
}));


router.get('/', function(req, res) {
    // req.session.generatedQuestions = true;
    var generateQuestions = req.app.get("generatedQuestions");
    console.log(generateQuestions);
   var formFields = [];
   // Generate the form
   if (!generateQuestions) {
    questions = generateFormFields(formFields);
    req.app.set("generatedQuestions", true);
   }

   console.log(questions);

   for (let i = 0; i < 5; i++) {
    formFields.push({label: questions[i].question, name : "Question " + i}) 
    answers.push(questions[i].answer);   
   }

   res.render("QuestionsPage", {formFields: formFields})

})

router.post('/', function(req,res) {
  req.app.set("answeredQuestions", true);
  console.log(checkAnswers(req.body, answers));

  console.log("redirecting");

  req.session.score = checkAnswers(req.body, answers);
  req.session.question_answer_pairs = questions;
  req.session.submittedAnswers = req.body;

  console.log(req.session);
  res.redirect("/feedback")
})

function generateFormFields (formFields) {
    // Read the questions.json file, and create a list of questions
    questionPool = [];

    var difficulties = require('../config.json');
    var questions = require('../questions.json');

    const SQLInjectionDifficulty = difficulties.vulnerabilities[0].SQL_Injection
    if (SQLInjectionDifficulty == 1) {
        sql_questions_diff_1 = questions.vulnerabilities.SQL_Injection.Difficulty[SQLInjectionDifficulty - 1];
        questionPool = questionPool.concat(sql_questions_diff_1);
    } else if (SQLInjectionDifficulty == 2) {
        sql_questions_diff_2 = questions.vulnerabilities.SQL_Injection.Difficulty[SQLInjectionDifficulty - 1];
        questionPool = questionPool.concat(sql_questions_diff_2);        
    }

    const AuthenticationDifficulty = difficulties.vulnerabilities[0].Authentication;
    if (AuthenticationDifficulty < 4) {
        authenticationQuestions = questions.vulnerabilities.Authentication;
        questionPool = questionPool.concat(authenticationQuestions);
    }
    const questionsList = getRandomElements(questionPool, 5)
    return questionsList;
}

function getRandomElements(list, n) {
      if (n > list.length)
      throw new RangeError("getRandomElements: more elements taken than available");

    let result = [];
    let tempArray = [...list]; // Clone the list to a temporary array

    while(n--) {
      const index = Math.floor(Math.random() * tempArray.length);
      result.push(tempArray[index]);
      tempArray.splice(index, 1); // Remove the chosen element from the temp array
    }
    return result;
  }
  
  const list = ["apple", "banana", "cherry", "date", "elderberry"];
  const randomElements = getRandomElements(list, 3);
  console.log(randomElements);
  
function checkAnswers(reqBody, answerList) {
  let score = 0;
  for (let i = 0; i < answerList.length; i++) {
      const question = `Question ${i}`;
    if (reqBody[question] === answerList[i]) {
      score++;
    }
  }
  return score;
}

module.exports = router;