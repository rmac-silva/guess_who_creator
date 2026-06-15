import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  highlightColor: Colors.blue.shade200,
  dividerColor: Colors.blue.shade200,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade200,
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Colors.black)
  )
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey.shade900,
  highlightColor: Colors.deepPurple.shade400.withAlpha(230),
  dividerColor: Colors.grey.shade800,
  
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade800,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Colors.white)
  )
);

extension SuccessColors on ThemeProvider {
  Color getTextColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  Color getSuccessColor() {
    return isDarkMode ? Colors.green.shade800 : Colors.green.shade300;
  }

  Color getErrorColor() {
    return isDarkMode ? Colors.red.shade500 : Colors.red.shade300;
  }

  Color getIncorrectGuessColor() {
    return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade300;
  }
  Color getIncorrectGuessColorNotLatest() {
    return isDarkMode ? Colors.orange.shade600.withAlpha( (0.75 * 255).floor() ) : Colors.orange.shade300.withAlpha( (0.75 * 255).floor() );
  }

  Color getPrimaryColor() {
    return isDarkMode ? darkTheme.primaryColor : lightTheme.primaryColor;
  }

  Color getSecondaryColor() {
    return isDarkMode ? darkTheme.highlightColor : lightTheme.highlightColor;
  }
  
}