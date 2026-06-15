import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:routemaster/routemaster.dart';

class GameCreationButton extends StatelessWidget {
  const GameCreationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final Size screenSize = MediaQuery.of(context).size;


    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(screenSize.width * 0.15, screenSize.height * 0.1),
            backgroundColor: themeProvider.isDarkMode ? darkTheme.highlightColor : lightTheme.highlightColor,
            foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Routemaster.of(context).push('/new_game'),
          // Use AutoSizeText here
          child: const AutoSizeText(
            'New Game',
            style: TextStyle(fontSize: 32), // This acts as the MAXIMUM size
            maxLines: 1,                    // Force it onto one line
            minFontSize: 4,                // Don't let it shrink past this
          ),
        ),
      ],
    );
  }
}
