import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pro/config/application.dart';
import 'package:http/http.dart' as http;
import 'package:pro/data/database.dart';
import 'package:pro/model/user.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:pro/widgets/correct_wrong_overlay.dart';

import 'package:pro/data/constants.dart' as constants;
import 'package:pro/model/ApiRequestResult.dart';

class QuizGame extends StatefulWidget {
  final subject;

  QuizGame({@required this.subject}){
    print("I have been summoned with this $subject");
  }

  @override
  _QuizGameState createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  int responseCode;
  List<Results> results;
  List<AnswerWidget> ansCards;
  String link;
  int nQuestions = 10;
  int score = 0;

  int questionNumber = 0;
  Color difficultyColor = Colors.greenAccent;
  int pointsForCorrectAnswer = 50;

  bool doneLoadingData = false;
  bool overlayShouldBeVisable = false;
  bool wasAnswerCorrect = false;
  User user;

  int correctAnswers = 0;

  var unescape = new HtmlUnescape();

  int maxScore = 0;

  @override
  void initState() {
    super.initState();

    link = "https://opentdb.com/api.php?amount=$nQuestions&category=${constants.subjects[widget.subject]}&type=multiple";
    print(link);

    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    var res = await http.get(link);
    var decRes = jsonDecode(res.body);
    print(decRes);

  
    fromJson(decRes);

    user = await Database().getCurrentUserData();
    setState(() {
      doneLoadingData = true;
    });
  }

  fromJson(Map<String, dynamic> json) {
    responseCode = json[constants.responseCode];
    if (json[constants.responseResult] != null) {
      results = List<Results>();
      json[constants.responseResult].forEach((v) {
        results.add(Results.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data[constants.responseCode] = this.responseCode;
    if (this.results != null) {
      data[constants.responseResult] = this.results.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        color: const Color(0xcc2c304d),
        child: doneLoadingData ? questionList() : Container(child: Center(child: CircularProgressIndicator()))
      ),
    );
  }

  setUpQuestion(){
    if(results[questionNumber].difficulty == constants.difficultyHard){
      difficultyColor = Colors.redAccent;
      pointsForCorrectAnswer = 200;
    }else if(results[questionNumber].difficulty == constants.difficultyMedium){
      difficultyColor = Colors.orangeAccent;
      pointsForCorrectAnswer = 100;
    }

  }



  Widget questionList() {
    String title = widget.subject;
    title = title.replaceAll("and", "&");

    setUpQuestion();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[ 
      Container(
        margin: EdgeInsets.only(top: 40.0, left: 15.0, right: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
                        child: Text(title,
                style: TextStyle(
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w300)),
            ),

            new Container(
              margin: EdgeInsets.only(bottom: 5.0, top: 25.0),
              alignment: Alignment.centerRight,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text("Question ${questionNumber + 1} of ${results.length}",
                      style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w300)),
                  new Text("Score: $score",
                      style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w300))
                ],
              ),
            ),
            Card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top:5.0),
                  alignment: Alignment.center,
                  child: Text(results[questionNumber].difficulty,
                      style: TextStyle(
                          color: difficultyColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 15.0)),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(
                      top: 65.0, bottom: 75.0, left: 15.0, right: 15.0),
                  child: Text(unescape.convert(results[questionNumber].question),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xcc2c304d))),
                ),
              ],
            )),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(right: 5.0, bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text("+$pointsForCorrectAnswer", style: TextStyle(color: Colors.greenAccent, fontSize: 15.0)),
                  Text(" points for the correct answer",
                      style: TextStyle(color: Colors.white))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top:30.0),
              child: Column(
                children: results[questionNumber].allAnswers.map((m) {
                  return AnswerWidget(results[questionNumber], m,answer);
                }).toList(),
              ),
            )
          ],
        ),
      ),
      overlayShouldBeVisable == true ? 
        Container(  
          child: CorrectWrongOverlay(wasAnswerCorrect,nextQuestion)
        ): Container()
    ]
    );
  }

 answer(bool correctAnswer){
    maxScore = maxScore + pointsForCorrectAnswer;

    if(correctAnswer){
      print("Correct!");
      correctAnswers++;
      wasAnswerCorrect = true;
      answeredCorrectly();
    }else {
      setState(() {
        wasAnswerCorrect = false;
        overlayShouldBeVisable = true;      
      });
      print("Wrong");
      
    }
  }

  answeredCorrectly(){
    setState(() {
      score = score+pointsForCorrectAnswer; 
      Database().addPoints(user, pointsForCorrectAnswer);
      overlayShouldBeVisable = true;
    }); 
  }

  nextQuestion(){
    if(questionNumber == results.length - 1){
      print("quiz is over!");
      print("You got $correctAnswers correct out of ${results.length}");


      Application.router.navigateTo(context, "/score?subject=${widget.subject}&score=$score&totalScore=$maxScore", clearStack: true);
    }else{
      setState(() {
        wasAnswerCorrect = false;
        overlayShouldBeVisable = false;
        questionNumber++;
      });
    }
  }


  Padding errorData(AsyncSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Error: ${snapshot.error}',
          ),
          SizedBox(
            height: 20.0,
          ),
          RaisedButton(
            child: Text("Try Again"),
            onPressed: () {
              fetchQuestions();
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Future<bool> _onWillPop() {
    Application.router.navigateTo(context, "/home?subject=quiz", clearStack: true);
  }

  String styleText(String title) {
    String upperCasetitle = title.toUpperCase();
    String result = "";

    for (int i = 0; i < upperCasetitle.length; i++) {
      result = result + upperCasetitle[i] + " ";
    }
    return result;
  }
}

class AnswerWidget extends StatefulWidget {

  final String m;
  final void Function(bool) answer;
  final Results result;


  AnswerWidget(this.result, this.m, this.answer);


  @override
  _AnswerWidgetState createState() => _AnswerWidgetState();
}

class _AnswerWidgetState extends State<AnswerWidget> {
  Color answerColor = Colors.white;
  bool correctAnswer = false;
  var unescape = new HtmlUnescape();

  answer(){
    setState(() {
      
      
      if (widget.result.correctAnswer == widget.m) {
        //answerColor = Colors.greenAccent;
        correctAnswer = true;
      }else {
        //answerColor = Colors.redAccent;
      }
      
      
      widget.answer(correctAnswer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: answerColor,
      margin: EdgeInsets.only(bottom: 20.0),
      child: ListTile(
        enabled: true,
        onTap: () => answer(),
        title: Text(
          unescape.convert(widget.m),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xcc2c304d),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}



