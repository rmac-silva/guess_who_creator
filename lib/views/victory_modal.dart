import 'package:flutter/material.dart';
import 'package:guess_who_creator/models/game.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/theme.dart';

class VictoryModal extends StatelessWidget {
  final List<String> correctGuesses;
  final int totalAttempts;
  final UploadedImageModel? image;

  const VictoryModal({
    super.key,
    required this.correctGuesses,
    required this.totalAttempts,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    return Dialog(
      backgroundColor: themeProvider.getPrimaryColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: IntrinsicWidth(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              const SizedBox(height: 20),
              if (image != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      image!.bytes,
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                "The correct answer was",
                style: TextStyle(
                  fontSize: 16, 
                  color: themeProvider.getTextColor().withAlpha(180),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correctGuesses.length > 1 ?  "${correctGuesses[0]} and more..." : correctGuesses[0],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.getTextColor(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.getSecondaryColor().withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "You took $totalAttempts attempts",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w600,
                    color: themeProvider.getTextColor(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.getSecondaryColor(),
                  foregroundColor: themeProvider.getTextColor(),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}