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

    // Mark all entries as uploading initially
    for (var entry in game.availableGuesses) {
      if (entry.image.status != UploadStatus.success) {
        entry.image.status = UploadStatus.uploading;
      }
    }
    notifyListeners();

    try {
      final String baseUrl = AppConfig.apiUrl;

      // --- PHASE 1: Initialize the Game Meta-Record (No images) ---
      final Uri initUrl = Uri.parse('$baseUrl/game/new');

      game.hasClues = _hasHints;
      game.hasMultipleGuesses = _hasMultipleGuesses;

      final initResponse = await http.post(
        initUrl,
        headers: {'Content-Type': 'application/json'},
        // Cleanly pass includeImages: false here to drop the heavy base64 payload strings
        body: game.jsonify(includeImages: false),
      );

      if (initResponse.statusCode != 200) {
        throw Exception(_parseServerError(initResponse));
      }

      final Map<String, dynamic> responseData = jsonDecode(initResponse.body);
      _gameID = responseData['gameId'] ?? "fallback_id";

      // --- PHASE 2: Upload Guess Cards in Batches of 50 ---
      final int chunkSize = 50;
      final int totalGuesses = game.availableGuesses.length;

      for (var i = 0; i < totalGuesses; i += chunkSize) {
        // Isolate our current slice block
        final int endRange = (i + chunkSize > totalGuesses)
            ? totalGuesses
            : i + chunkSize;
        final chunk = game.availableGuesses.sublist(i, endRange);

        // Serialize just this current index chunk (includes full base64 image data)
        final Map<String, dynamic> batchPayload = {
          "guesses": chunk
              .map((guess) => guess.toJson(_hasMultipleGuesses, _hasHints))
              .toList(),
        };

        final Uri batchUrl = Uri.parse('$baseUrl/game/$_gameID/upload-guesses');

        final batchResponse = await http.post(
          batchUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(batchPayload),
        );

        if (batchResponse.statusCode == 200) {
          // Incrementally mark uploaded items in this slice block as successful
          for (var entry in chunk) {
            entry.image.status = UploadStatus.success;
          }
          notifyListeners(); // Updates UI to show these 50 are done!
        } else {
          throw Exception(_parseServerError(batchResponse));
        }
      }
    } catch (e) {
      // If anything fails anywhere in Phase 1 or Phase 2, catch it and set errors flag
      for (var entry in game.availableGuesses) {
        if (entry.image.status == UploadStatus.uploading) {
          entry.image.status = UploadStatus.error;
          entry.image.errorMessage = e.toString();
        }
      }
      notifyListeners();
      throw Exception('Upload Failed: ${e.toString()}');
    }

    var templateMessage = email.isEmpty
        ? "You can now access your created game through the provided link.\nSince you have not provided an email, be sure to copy the link and saving it before leaving the page.\nGames that see no activity for a week are automatically deleted."
        : "You can now access your created game through the provided link.\nThe link was also sent to your email.\nGames that see no activity for a week are automatically deleted.";

    _generatedMessage = templateMessage;
    return true;
  }

  /// Helper method to cleanly extract system errors from failed requests
  String _parseServerError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return errorData['detail'] ?? response.body;
    } catch (_) {
      return "Status ${response.statusCode}: ${response.body}";
    }
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

    if (value == false) {}
  }
}
