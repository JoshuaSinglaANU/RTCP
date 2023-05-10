var express = require('express');
var router = express.Router();
const https = require('https');
var fs = require('fs');
var bcrypt = require("bcrypt")
var crypto = require("crypto")
const sqlite3 = require('sqlite3').verbose()
const { Sequelize, DataTypes } = require('sequelize');
const session = require('express-session');

router.get('/', function(req, res) {
    console.log("FEEDBACK")
    // Render the 'index' jade file

    routerSession = req.session;

    qna = routerSession.question_answer_pairs;
    submittedAnswers = routerSession.submittedAnswers;

    var formFields = [];
    if (req.app.get("answeredQuestions")) {
        console.log("TEST1");
    for (let i = 0; i < 5; i++) {
        formFields.push({question: qna[i].question, userAnswer: submittedAnswers[`Question ${i}`], correctAnswer :qna[i].answer})
    }
    console.log("TEST");
    console.log(formFields);
    res.render("feedback", {score: routerSession.score, feedbacks: formFields});
    } else {
        res.redirect("/answer");
    }

})

module.exports = router;