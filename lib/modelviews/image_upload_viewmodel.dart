import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:guess_who_creator/models/game.dart';
import 'package:guess_who_creator/utils/http_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadViewModel extends ChangeNotifier {
  final NewGuessingGame game = NewGuessingGame();

  String _generatedMessage = "";
  String _gameID = "";

  bool _hasHints = false;
  bool _hasMultipleGuesses = false;

  List<ImageGuess> get gameEntries => game.availableGuesses;
  String get generatedMessage => _generatedMessage;
  String get gameID => _gameID;

  bool get hasHints => _hasHints;
  bool get hasMultipleGuesses => _hasMultipleGuesses;

  bool get isUploading => game.availableGuesses.any(
    (entry) => entry.image.status == UploadStatus.uploading,
  );
  
  bool get hasUnlabeledImages => game.availableGuesses.any((entry) {
      // 1. Invalid if the list itself is completely empty
      if (entry.guessNames.isEmpty) return true;
      
      // 2. Invalid if any individual text field contains only whitespace or is empty
      return entry.guessNames.any((name) => name.trim().isEmpty);
    });

  // 1. Pick Multiple Images from Device
  Future<void> pickImages() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Crucial! Populates the bytes property
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.bytes != null) {
            // Avoid adding duplicates by checking the filename
            if (!game.availableGuesses.any(
              (entry) => entry.image.name == file.name,
            )) {
              game.availableGuesses.add(
                ImageGuess(
                  guessId:
                      DateTime.now().microsecondsSinceEpoch.toString() +
                      file.name,
                  image: UploadedImageModel(
                    name: file.name,
                    bytes: file.bytes!,
                  ),
                ),
              );
            }
          }
        }
        notifyListeners(); // Tell the View to rebuild and show the new images
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  // 2. Upload Images to Application/Server, creating the game
  Future<bool> createGame(String email) async {
    if (game.availableGuesses.isEmpty) return false;

    game.authorEmail = email;

    for (var entry in game.availableGuesses) {
      if (entry.image.status != UploadStatus.success) {
        entry.image.status = UploadStatus.uploading;
      }
    }

    notifyListeners();

    try {
      final String baseUrl = AppConfig.apiUrl;
      final Uri url = Uri.parse('$baseUrl/game/new');

      //Updating the flags for the model
      game.hasClues = _hasHints;
      game.hasMultipleGuesses = _hasMultipleGuesses;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: game.jsonify(), // Uses the method we created earlier
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract the real game ID sent by your FastAPI backend
        _gameID = responseData['gameId'] ?? "fallback_id";

        // Mark all uploads as successful
        for (var entry in game.availableGuesses) {
          entry.image.status = UploadStatus.success;
        }
      } else {
        String errorDetail = "Server error";
        try {
          final errorData = jsonDecode(response.body);
          errorDetail = errorData['detail'] ?? response.body;
        } catch (_) {
          errorDetail = "Status ${response.statusCode}: ${response.body}";
        }
        throw Exception(errorDetail);
      }
    } catch (e) {
      for (var entry in game.availableGuesses) {
        if (entry.image.status == UploadStatus.uploading) {
          entry.image.status = UploadStatus.error;
          entry.image.errorMessage = e.toString();
        }
      }
      notifyListeners();
      throw Exception('Server returned status code: ${e.toString()}');
    }

    var templateMessage = email.isEmpty
        ? "You can now access your created game through the provided link.\nSince you have not provided an email, be sure to copy the link and saving it before leaving the page.\nGames that see no activity for a week are automatically deleted."
        : "You can now access your created game through the provided link.\nThe link was also sent to your email.\nGames that see no activity for a week are automatically deleted.";

    _generatedMessage = templateMessage;

    return true;
  }

  // 3. Remove an image from the list
  void removeImage(String id) {
    game.availableGuesses.removeWhere((entry) => entry.guessId == id);
    notifyListeners();
  }

  // 4. Change a label for a given image in the list
  void changeImageLabels(String id, List<String> newLabels) {
    // Find the exact entry matching the ID
    final entryToChange = game.availableGuesses.firstWhere(
      (entry) => entry.guessId == id,
      orElse: () => throw Exception('ImageGuess entry not found'),
    );

    // Update the entire list of guess names
    entryToChange.guessNames = newLabels;

    // Alert Flutter to re-render the UI
    notifyListeners();
  }

  void changeImageClues(String id, List<String> newClues) {
    // Find the exact entry matching the ID
    final entryToChange = game.availableGuesses.firstWhere(
      (entry) => entry.guessId == id,
      orElse: () => throw Exception('ImageGuess entry not found'),
    );

    // Update the entire list of clues
    entryToChange.clues = newClues;

    // Alert Flutter to re-render the UI
    notifyListeners();
  }

  void changeGameName(String newTitle) {
    game.gameName = newTitle;
    notifyListeners();
  }

  void toggleHints(bool value) {
    _hasHints = value;

    
  }

  void toggleMultipleGuesses(bool value) {
    _hasMultipleGuesses = value;

    if(value == false) {
      
    }
  }
}
