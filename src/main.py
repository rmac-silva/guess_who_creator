from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
import os
import uvicorn

from utils.db_manager import DatabaseManager
from utils.logger import Logger
from dotenv import load_dotenv


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
try:
    load_dotenv()  # Load environment variables from a .env file
except Exception as e:
    print(f"Error loading .env file: {e}\n")

origins = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")

# JWT Secrets - Fetched from .env file
DB_PATH = os.getenv("DB_PATH", "NO_VALID_DATABASE_PATH")

# /logs under DB Path
LOG_PATH = os.path.join(os.path.dirname(DB_PATH), "logs")


lg = Logger(folderpath=LOG_PATH)

# Database access
db = DatabaseManager(DB_PATH)

# Info Manager

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/game/new")
def new_game(data : dict):
    lg.log(f"@POST [/game/new] - Creating a new game \"{data.get('gameName',"NO_NAME")}\"")
    
    res = db.create_new_game(data)
    if(res[0] == "200"):
        return {"status": res[0], "gameId": res[1], "error" : ""}
    else:
        raise HTTPException(status_code=500, detail=res[1])
    
@app.get("/game/{gameid}")
def fetch_daily_game(gameid : str):
    print(f"Fetching game with id: {gameid}")
    lg.log(f"@GET [/game/{gameid}] - Fetching a daily game: {gameid}")
    
    res = db.fetch_daily_game(gameid)
    if(res[0] == "200"):
        return {"status": res[0], "content" : res[1]}
    else:
        raise HTTPException(status_code=500,detail=res[1])
    
@app.post("/game/{gameid}/upload-guesses")
def upload_game_guesses(gameid: str, data: dict):
    lg.log(f"@POST [/game/{gameid}/upload-guesses] - Appending batch of guesses to game {gameid}")
    
    # Process the chunk of guesses via the database manager
    res = db.add_guesses_to_game(gameid, data.get("guesses", []))
    
    if res[0] == "200":
        return {"status": "200", "message": res[1], "error": ""}
    elif res[0] == "404":
        raise HTTPException(status_code=404, detail=res[1])
    else:
        raise HTTPException(status_code=500, detail=res[1])
    
def find_ip():
    import socket

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]


BASE_DIR = Path(__file__).resolve().parent
CERT_DIR = BASE_DIR / "certs"
RUNNING_ON_CONTAINER = os.getenv("RUNNING_ON_CONTAINER", "false").lower() == "true"

if __name__ == "__main__":
    if RUNNING_ON_CONTAINER:
        uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
    else:
        # uvicorn.run("main:app", host=find_ip(), port=8000,ssl_keyfile=str(CERT_DIR / 'localhost-key.pem'), ssl_certfile=str(CERT_DIR / 'localhost.pem'), reload=True)
        uvicorn.run("main:app", host=find_ip(), port=8000, reload=True)


"""
Redo the router with schemas https://gemini.google.com/app/b9dfe4b52c058eec?hl=pt-PT
"""
