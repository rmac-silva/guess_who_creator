import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:guess_who_creator/models/game.dart';
import 'package:guess_who_creator/utils/http_utils.dart';
import 'package:http/http.dart' as http;

class GameViewModel extends ChangeNotifier {
  GuessingGame? _game;
  final List<String> _previousGuesses = [];

  bool _isLoading = true;
  bool _wonGame = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get wonGame => _wonGame;

  String? get errorMessage => _errorMessage;

  String? get gameTitle => _game?.gameTitle;
  List<String>? get correctAnswers => _game?.puzzle.guessNames;
  List<String>? get clues => _game?.puzzle.clues;
  List<String> get previousGuesses => _previousGuesses;
  UploadedImageModel? get image => _game?.puzzle.image;

  int _clueIndex = 0;
  int get clueIndex => _clueIndex;

  GameViewModel(String gameID) {
    _fetchGameData(gameID);
  }

  Future<void> _fetchGameData(String gameID) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners(); // Tell the UI to update

      final String baseUrl = AppConfig.apiUrl;
      final Uri url = Uri.parse('$baseUrl/game/$gameID');
      print("Fetching game at: $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> content = data['content'];

        final Uint8List imageBytes = base64Decode(content['image']);

        _game = GuessingGame(
          gameID: content['gameID'],
          gameTitle: content['title'],
          puzzle: ImageGuess(
            guessId: "puzzle_${content['gameID']}", // Synthetic ID
            guessNames: List<String>.from(content['guesses'] as List),
            clues: List<String>.from(content['clues'] as List),
            image: UploadedImageModel(
              name: content['image_name'] ?? "puzzle_image.png",
              bytes: imageBytes,
            ),
          ),
        );
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

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      print(e.toString());
      _errorMessage = "Failed to load the game: ${e.toString()}";
    } finally {
      notifyListeners(); //Update the UI again
    }
  }

  void addGuess(String guess) {
    var matchingGuesses = correctAnswers?.firstWhere((entry) => entry == guess);
    if (matchingGuesses != null && matchingGuesses.isNotEmpty) {
      _wonGame = true;
    }

    _previousGuesses.add(guess);
    notifyListeners();
  }

  void showClue() {
    print("Clicked hint button");
    // 1. If the game hasn't initialized yet, return an empty string safely
    if (_game == null) {
      print("Game is still loading or null!");
      return;
    }

    // 2. Check if the requested index is out of bounds for the current clues list
    // (e.g., if length is 1, a clueIndex of 1 or higher is out of bounds)
    if (_clueIndex >= _game!.puzzle.clues.length) {
      print("No more hints to show!");
      return;
    }

    // 3. If it's safe, return the clue at that exact index
    _clueIndex++;
    print("Showing next hint!");
    notifyListeners();
  }

  bool hasNextClue() {
    if (_game == null) {
      return false;
    }

    // 2. Check if the requested index is out of bounds for the current clues list
    // (e.g., if length is 1, a clueIndex of 1 or higher is out of bounds)
    if (_clueIndex >= _game!.puzzle.clues.length) {
      return false;
    }

    return true;
  }
}
