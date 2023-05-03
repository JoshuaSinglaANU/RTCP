var express = require('express');
var router = express.Router();
var questions = [];

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

    for (var question of questions) {
        formFields.push({label: question, name : question})
    }

   res.render("QuestionsPage", {formFields: formFields})

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
    if (AuthenticationDifficulty <= 4) {
        authenticationQuestions = questions.vulnerabilities.Authentication;
        questionPool = questionPool.concat(authenticationQuestions);
    }
    const questionsList = getRandomElements(questionPool, 5)
    return questionsList;
}

function getRandomElements(list, n) {
    const result = new Array(n);
    let len = list.length;
    const taken = new Array(len);
    if (n > len)
      throw new RangeError("getRandomElements: more elements taken than available");
  
    while (n--) {
      const x = Math.floor(Math.random() * len);
      result[n] = list[x in taken ? taken[x] : x];
      taken[x] = --len in taken ? taken[len] : len;
    }
    return result;
  }
  
  const list = ["apple", "banana", "cherry", "date", "elderberry"];
  const randomElements = getRandomElements(list, 3);
  console.log(randomElements);
  

module.exports = router;