
from pathlib import Path
import sqlite3



def setup_database(db_path : str):
    db_path_str: str = db_path
    db_path_path: Path = Path(db_path_str)

    # Ensure parent directory exists (important for Docker volumes)
    db_path_path.parent.mkdir(parents=True, exist_ok=True)
    
    
    
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    conn.execute("PRAGMA foreign_keys = ON;")
    
    #Database functions go here
    create_games_table(c)
    create_sqlar_table(c)
    create_guesses_table(c)
    
    conn.commit()
    conn.close()
    
def create_games_table(c : sqlite3.Cursor):
    
    cmd = """
        CREATE TABLE IF NOT EXISTS games (
            gameID TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            email TEXT,
            lastPlayed INTEGER NOT NULL,
            permanent BOOL DEFAULT 0
        )
    """
    c.execute(cmd)
    

def create_guesses_table(c : sqlite3.Cursor):
    
    cmd = """
        CREATE TABLE IF NOT EXISTS guesses (
        gameID TEXT NOT NULL,
        guess TEXT NOT NULL,
        filename TEXT NOT NULL,
        PRIMARY KEY (gameID, filename),
        FOREIGN KEY (gameID) REFERENCES games(gameID) ON DELETE CASCADE,
        FOREIGN KEY (filename) REFERENCES sqlar(name)
    );
        """
    
    c.execute(cmd)
    
def create_sqlar_table(c : sqlite3.Cursor):
    
    cmd = """
        CREATE TABLE IF NOT EXISTS sqlar (
            name TEXT PRIMARY KEY,
            mode INT,
            mtime INT,
            sz INT,
            data BLOB
        )
    """
    
    c.execute(cmd)
    
    
    