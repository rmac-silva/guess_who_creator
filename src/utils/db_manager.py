import base64
from datetime import datetime
import json
import random
import sqlite3
import time
import utils.db_setup as db_setup
import threading

ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


class DatabaseManager:

    def __init__(self, db_path: str):
        self.db_path = db_path

        db_setup.setup_database(db_path)

        # Launch the backup thread
        backup_thread = threading.Thread(target=self.backup_database, daemon=True)
        backup_thread.start()

        # Launch the cleanup thread
        cleanup_thread = threading.Thread(target=self.cleanup_task, daemon=True)
        cleanup_thread.start()

    def cleanup_task(self, interval: int = 86400):
        """Runs the cleanup task every 24 hours"""
        while True:
            self.delete_inactive_games()
            time.sleep(interval)

    def c(self):
        conn = sqlite3.connect(self.db_path)
        return conn.cursor()

    def backup_database(self, backup_interval: int = 86400) -> bool:
        """Creates a backup of the database. Creating a copy of the current database file with a timestamp extension.
        By default backs up the database every 24hrs, keeping a maximum of 5 copies.

        This function is thread safe, since it will be run in a separate thread by the main application.
        Args:
            backup_interval (int, optional): Interval in seconds between backups. Defaults to 86400.

        Returns:
            bool: _description_
        """
        import os
        import time
        from datetime import datetime
        from glob import glob
        import shutil
        from pathlib import Path

        db_path = Path(self.db_path)
        backups_dir = db_path.parent / "backups"
        backups_dir.mkdir(parents=True, exist_ok=True)

        while True:
            # Clean up old backups, keeping only the most recent 5
            backup_files = glob(f"{self.db_path}-backup-*.db")
            backup_files.sort(key=os.path.getmtime, reverse=True)

            if len(backup_files) == 6:
                # Delete oldest
                os.remove(backup_files[0])

            timestamp = datetime.now().strftime("%d-%m---%H-%M-%S")
            backup_path = f"{self.db_path}-backup-{timestamp}.db"
            shutil.copy2(self.db_path, backup_path)

            print(f"Database backed up at {timestamp} to {backup_path}. Waiting for {backup_interval} seconds until next backup.")
            time.sleep(backup_interval)

    def create_new_game(self, data: dict) -> tuple[str, str]:
        """Creates a new game

        Args:
            data (dict): {
                gameName : str,
                authorEmail : str,
                availableGuesses : [
                    guessId : str,
                    'image' :  {
                        'name' : str,
                        'bytes' : bytes
                    }
                    guessNames : [str],
                    clues : []
                ]
            }
        """

        gameName = data.get("gameName", "")
        authorEmail = data.get("authorEmail", "")
        available_guesses = data.get("availableGuesses", [])

        game_id = "".join(random.choices(ALPHABET, k=8)) + str(time.time()).replace(".", "")

        c = self.c().connection

        print(f'Creating a new game "{gameName}", from "{authorEmail}" with {len(available_guesses)} guesses.\nWith ID {game_id}')

        try:

            c.execute(
                """
                INSERT INTO games (gameID, title, email, lastPlayed)
                VALUES (?,?,?,?)
                """,
                (game_id, gameName, authorEmail, int(time.time())),
            )

            for guess in available_guesses:
                possible_guesses = guess.get("guessNames", [])
                game_clues = guess.get("clues",[])
                print(f"New game - This guess has {len(possible_guesses)} correct answers. And it has {len(game_clues)} clues\n")
                image_data = guess.get("image", {})

                filename = image_data.get("name", "image.png")
                b64_string = image_data.get("bytes", "")

                image_bytes = base64.b64decode(b64_string)

                # Ensure the sqlar path is always different
                storage_path = f"{game_id}/{filename}"

                c.execute(
                    """
                    INSERT INTO sqlar (name, mode, mtime, sz, data)
                    VALUES (?,?,?,?,?)
                    """,
                    (storage_path, 33188, int(time.time()), len(image_bytes), image_bytes),
                )

                c.execute(
                    """
                    INSERT INTO guesses (gameID, possibleGuesses, clues, filename)
                    VALUES(?,?,?,?)
                    """,
                    (game_id, json.dumps(possible_guesses), json.dumps(game_clues), storage_path),
                )

                print("\nGame created successfuly")
                c.commit()

            return ("200", game_id)

        except Exception as e:
            c.rollback()
            return ("500", f"Error creating game: {e}")

    def fetch_game_information(self, gameid: str):
        """Fetches all of the information about a given game, so the players can edit their creations"""
        pass

    def fetch_daily_game(self, gameid: str) -> tuple[str, str | dict]:
        """Fetches a daily guess from a game"""

        # 1. Prepare seed and fetch meta-data ONLY (exclude sqlar.data for now)
        daily_seed = datetime.now().strftime("%Y-%m-%d")
        
        try:
            # Use 'with' to ensure the connection closes automatically
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Only fetch small text fields first
                fetch_possible_games = """
                SELECT games.title, guesses.filename
                FROM games
                INNER JOIN guesses ON games.gameID = guesses.gameID
                WHERE games.gameID = ?;
                """
                
                cursor.execute(fetch_possible_games, (gameid,))
                entries = cursor.fetchall()

                if not entries:
                    return ("404", f"Could not find a valid guess for game {gameid}")

                # 2. Sort the list to guarantee the seed always picks the same index
                entries.sort(key=lambda x: x[1]) # Sort by filename

                # 3. Pick the character
                rng = random.Random(daily_seed)
                picked_entry = rng.choice(entries)
                filename = picked_entry[1]

                # 4. NOW fetch the heavy image data for only the character we want
                cursor.execute("SELECT data FROM sqlar WHERE name = ?", (filename,))
                image_blob = cursor.fetchone()[0]
                
                # 5. Fetch the guesses and clues from the picked entry
                fetch_detailed_info = """
                SELECT possibleGuesses, clues
                FROM guesses
                WHERE gameID = ? AND filename = ?;
                """
                
                details = cursor.execute(fetch_detailed_info, (gameid,filename)).fetchone()

                # Update activity
                self.mark_game_played(gameid)

                image_b64 = base64.b64encode(image_blob).decode("utf-8")
                res = {
                    "gameID": gameid,
                    "title": picked_entry[0],
                    "guesses": json.loads(details[0]),
                    "clues": json.loads(details[1]),
                    "image": image_b64,
                    "image_name": filename.split("/")[-1]
                }
                print(f"\nFetched: {gameid}, {picked_entry[0]}, {json.loads(details[0])}, {json.loads(details[1])}, {filename.split("/")[-1]}")
                return ("200", res)
        except Exception as e:
            return ("500", f"Error creating game: {e}")

    def mark_game_played(self, game_id: str):
        """Marks a game as played so it doesn't get deleted by the automatic cleanup"""
        now = int(time.time())
        conn = sqlite3.connect(self.db_path)
        try:
            conn.execute("UPDATE games SET lastPlayed = ? WHERE gameID = ?", (now, game_id))
            conn.commit()
        except Exception as e:
             print(f"Error marking game as played: {e}")
        finally:
            conn.close()

    def delete_inactive_games(self):
        """Deletes the inactive games, those who haven't been played for more than two weeks"""
        two_weeks_ago = int(time.time()) - (14 * 24 * 60 * 60)
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            # Find filenames to delete in sqlar
            cursor.execute("SELECT filename FROM guesses WHERE gameID IN (SELECT gameID FROM games WHERE lastPlayed < ? AND permanent = 0)", (two_weeks_ago,))
            filenames = [row[0] for row in cursor.fetchall()]
            
            for filename in filenames:
                cursor.execute("DELETE FROM sqlar WHERE name = ?", (filename,))
            
            cursor.execute("DELETE FROM games WHERE lastPlayed < ? AND permanent = 0", (two_weeks_ago,))
            conn.commit()
            print("Deleted inactive games and their assets.")
        except Exception as e:
            print(f"Error deleting inactive games: {e}")
            conn.rollback()
        finally:
            conn.close()

    def add_guesses_to_game(self, game_id: str, guesses_chunk: list) -> tuple[str, str]:
        """Appends a chunk of guesses and image payloads to an existing game ID safely.
        
        Args:
            game_id (str): Target game key
            guesses_chunk (list): [
                {
                    'image': {'name': str, 'bytes': str},
                    'guessNames': [str],
                    'clues': []
                }
            ]
        """
        import sqlite3
        import base64
        import json
        import time

        try:
            with sqlite3.connect(self.db_path) as conn:
                c = conn.cursor()
                
                # Verify that the parent game actually exists first
                c.execute("SELECT gameID FROM games WHERE gameID = ?", (game_id,))
                if not c.fetchone():
                    return ("404", f"Game ID {game_id} not found.")

                print(f"Uploading batch of {len(guesses_chunk)} assets for Game ID: {game_id}")

                for guess in guesses_chunk:
                    possible_guesses = guess.get("guessNames", [])
                    game_clues = guess.get("clues", [])
                    image_data = guess.get("image", {})

                    filename = image_data.get("name", "image.png")
                    b64_string = image_data.get("bytes", "")

                    if not b64_string:
                        continue # Skip entry if it accidentally missing raw byte streams

                    # Unpack base64 payload to binary data
                    image_bytes = base64.b64decode(b64_string)
                    storage_path = f"{game_id}/{filename}"

                    # Insert image bytes directly into sqlar blob storage
                    c.execute(
                        """
                        INSERT OR REPLACE INTO sqlar (name, mode, mtime, sz, data)
                        VALUES (?, ?, ?, ?, ?)
                        """,
                        (storage_path, 33188, int(time.time()), len(image_bytes), image_bytes),
                    )

                    # Insert cross reference into guesses mapping table
                    c.execute(
                        """
                        INSERT OR REPLACE INTO guesses (gameID, possibleGuesses, clues, filename)
                        VALUES (?, ?, ?, ?)
                        """,
                        (game_id, json.dumps(possible_guesses), json.dumps(game_clues), storage_path),
                    )

                conn.commit()
                return ("200", f"Successfully appended {len(guesses_chunk)} assets.")

        except Exception as e:
            return ("500", f"Database batch upload failed: {e}")