import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:guess_who_creator/views/image_picker.dart';
import 'package:guess_who_creator/views/links.dart';
import 'package:guess_who_creator/views/theme_switch.dart';

class NewGamePage extends StatelessWidget {
  const NewGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    

    // Look up the theme state from the root
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("New Game"),
        actions: [
          ThemeSwitch(
            value: themeProvider.isDarkMode,

            onChanged: themeProvider.onThemeChanged,
          ),
        ],
      ),

      

      body: SingleChildScrollView(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height*0.867,
              ),
              child: Container(
                color: themeProvider.isDarkMode
                    ? darkTheme.primaryColor
                    : lightTheme.primaryColor,
                    width: screenSize.width,
                child: Column(
                  spacing: 0,
                  children: [
                    ImageUploadWidget()
                  
                  ],
                ),
              ),
            ),

            

            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 70,
                maxHeight: screenSize.height * 0.6 > 70 ? screenSize.height * 0.6 : 70,
              ),
              child: Container(
                height: screenSize.height * 0.06,
                color: themeProvider.isDarkMode
                    ? darkTheme.dividerColor
                    : lightTheme.dividerColor,
                alignment: Alignment.center,
                child: LinkFooter(gamePage: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

