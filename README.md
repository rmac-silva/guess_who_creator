# About
This was a project developed to gain some experience using Flutter and Dart. Paired with a FastAPI backend. 
The project itself is a simple tool to create daily games to guess a specific character or content of an image.
Users upload their images, assign them the correct guess or guesses, and optionally include clues for the player.
Then, through a game-specific link, they can access the game's page, which refreshes the guess daily.
Games are deleted after a week of inactivity to save on storage. As the creation of games requires no signup.

## TODO
- Implement a simple email out to users, with the link to access the game in case they lose the one provided after game creation;
- Implement a way to edit pre-existing games, download them in a JSON format and import JSONs when creating new games.
- Ensure the same guess isn't picked two days in a row

# Running Flutter 

## Dev
flutter run --dart-define-from-file=config/dev.json  -d edge --web-port 54005

## Prod

# Running FastAPI

python main.py

## TODO
- Remove (1) (2) from filenames, and strip
- Add options to accept multiple names, provide hints
