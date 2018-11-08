import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import './route_handlers.dart';

class Routes {
  static String root = "/";
  static String login = "/login";
  static String register = "/register";
  static String home = "/home";
  static String onBoarding = "/onBoarding";
  static String quiz = "/quiz";


  static void configureRoutes(Router router) {
    router.notFoundHandler = new Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      print("ROUTE WAS NOT FOUND !!!");
    });
    router.define(root, handler: rootHandler);
    router.define(login, handler: loginHandler);
    router.define(register, handler: registerHandler);
    router.define(home, handler: homeHandler);
    router.define(onBoarding, handler: onBoardingHandler);
    router.define(quiz, handler: quizHandler);
  }
}
