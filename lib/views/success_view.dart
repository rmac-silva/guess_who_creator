import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/http_utils.dart';
import 'package:routemaster/routemaster.dart';

class SuccessView extends StatelessWidget {
  final String title;
  final String message;
  final String gameId;

  const SuccessView({
    super.key,
    required this.title,
    required this.message,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Listen to your custom ThemeProvider
    final themeProvider = ThemeProvider.of(context);
    final isDark = themeProvider.isDarkMode;

    // 2. Build the dynamic URL string
    final String baseOrigin = Uri.base.origin;
    final String fullGameUrl = '$baseOrigin/#/game/$gameId';

    // 3. Define adaptive colors based on the theme state
    final backgroundColor = isDark ? const Color(0xff121212) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xff212121);
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    const linkColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline, 
                  color: Colors.green, 
                  size: 70
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: primaryTextColor
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 20, 
                    color: secondaryTextColor,
                  ),
                  maxLines: 8,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // 4. Clean, bare hyperlink that copies text on click
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: fullGameUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      fullGameUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: linkColor,
                        fontSize: 24,
                        decoration: TextDecoration.underline,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                ElevatedButton(
                  onPressed: () => Routemaster.of(context).push('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}