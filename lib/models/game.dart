import 'dart:convert';
import 'dart:typed_data';

enum UploadStatus { idle, uploading, success, error }

class GuessingGame {
  final String gameID;
  final String gameTitle;
  final ImageGuess puzzle;

  GuessingGame({required this.gameID, required this.gameTitle, required this.puzzle});

  
}

class NewGuessingGame {
  List<ImageGuess> availableGuesses = List.empty(growable: true);
  String gameName = "";
  String? authorEmail;

  bool hasMultipleGuesses = false;
  bool hasClues = false;

  NewGuessingGame();

  // 1. Added an optional includeImages parameter (defaults to true)
  Map<String, dynamic> toJson({bool includeImages = true}) {
    return {
      'gameName' : gameName,
      'authorEmail' : authorEmail ?? "",
      'availableGuesses' : availableGuesses.map(
        (guess) => guess.toJson(hasMultipleGuesses, hasClues, includeImages: includeImages)
      ).toList()
    };
  }

  // 2. Forward the parameter to jsonify
  String jsonify({bool includeImages = true}) {
    return jsonEncode(toJson(includeImages: includeImages));
  }
}

class ImageGuess {
  final String guessId;
  final UploadedImageModel image;
  List<String> guessNames;
  List<String> clues = const [];

  static final RegExp _numericSuffixRegex = RegExp(r'\s*\(\d+\)');
  
  ImageGuess({
    required this.guessId,
    required this.image,
    List<String> guessNames = const [],
    List<String> clues = const [],
  }) : guessNames = guessNames.isEmpty 
          ? [image.name.split('.')[0].replaceAll(_numericSuffixRegex, '')] 
          : guessNames, 
       clues = clues.isEmpty ? [] : clues;

  // 3. Added includeImages parameter here to conditionalize the 'image' property mapping
  Map<String, dynamic> toJson(bool hasMultiple, bool hasclues, {bool includeImages = true}) {
    return {
      'guessId' : guessId,
      // If false, it completely omits the heavy inner base64 map structure
      'image' : includeImages ? image.toJson() : {}, 
      'guessNames' : hasMultiple ? guessNames : [guessNames[0]],
      'clues' : hasclues ? clues : [],
    };
  }
}

class UploadedImageModel {
  final String name;
  final Uint8List bytes; 
  UploadStatus status;
  String? errorMessage;

  UploadedImageModel({
    required this.bytes,
    this.status = UploadStatus.idle,
    this.errorMessage,
    required this.name
  });

  Map<String,dynamic> toJson() {
    return {
      'name' : name,
      'bytes' : base64Encode(bytes)
    };
  }
}