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

  Map<String, dynamic> toJson() {
    return {
      'gameName' : gameName,
      'authorEmail' : authorEmail ?? "",
      'availableGuesses' : availableGuesses.map( (guess) => guess.toJson(hasMultipleGuesses, hasClues)).toList()
    };
  }


  String jsonify() {
    return jsonEncode(toJson());
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
    
  }) : guessNames = guessNames.isEmpty ? [image.name.split('.')[0].replaceAll(_numericSuffixRegex, '')] : guessNames, clues = clues.isEmpty ? [] : clues;

  Map<String, dynamic> toJson(bool hasMultiple, bool hasclues) {
    return {
      'guessId' : guessId,
      'image' : image.toJson(),
      'guessNames' : hasMultiple ? guessNames : [guessNames[0]],
      'clues' : hasclues ? clues : [],
    };
  }

}

class UploadedImageModel {
 
  final String name;
  final Uint8List bytes; // Storing bytes ensures it works on iOS, Android, and Web
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