import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:guess_who_creator/views/create_game_button.dart';
import 'package:guess_who_creator/views/links.dart';
import 'package:guess_who_creator/views/theme_switch.dart';

class GuessWhoHomepage extends StatelessWidget {
  const GuessWhoHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double height = screenSize.height;

    // Look up the theme state from the root
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("HypothesizeTheIndividual"),
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
                minHeight: 450,
                maxHeight: height * 0.88 > 450 ? height * 0.88 : 450,
              ),
              child: Container(
                color: themeProvider.isDarkMode
                    ? darkTheme.primaryColor
                    : lightTheme.primaryColor,
                child: Column(
                  spacing: 0,
                  children: [
                    HomepageBrief(
                      theme: themeProvider.isDarkMode ? darkTheme : lightTheme,
                      screenSize: screenSize,
                    ),
                    GameCreationButton(),
                  ],
                ),
              ),
            ),

            

            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 70,
                maxHeight: height * 0.6 > 70 ? height * 0.6 : 70,
              ),
              child: Container(
                height: height * 0.06,
                color: themeProvider.isDarkMode
                    ? darkTheme.dividerColor
                    : lightTheme.dividerColor,
                alignment: Alignment.center,
                child: LinkFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomepageBrief extends StatelessWidget {
  final ThemeData theme;
  final Size screenSize;

  const HomepageBrief({
    super.key,
    required this.theme,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.directional(
        start: screenSize.width * 0.1,
        end: screenSize.width * 0.15,
        top: screenSize.height * 0.3,
        bottom: screenSize.height * 0.03
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: theme.highlightColor,
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),

          child: Container(
            alignment: Alignment.center,
            child: WelcomeText()
          ),
        ),
      ),
    );
  }
}

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText.rich(
      TextSpan(
        // This is your maximum base style for the entire paragraph
        style: const TextStyle(fontSize: 40),
        children: [
          const TextSpan(text: "Welcome to the "),
          TextSpan(
            text: "HypothesizeTheIndividual",
            style: const TextStyle(
              fontSize: 36, // This will scale down proportionally with the base size
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(
            text: " game maker. Below you can create custom, daily, guessing games based on your pictures.",
          ),
        ],
      ),
      maxLines: 3,         // Set the maximum lines you want to allow before it begins shrinking
      minFontSize: 6,     // The absolute smallest the font size should drop to
      overflow: TextOverflow.ellipsis, // Fallback if it still doesn't fit at minFontSize
      textAlign: TextAlign.center,
    );
  }
}