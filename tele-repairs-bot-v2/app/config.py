import os
from pydantic import BaseModel

class Settings(BaseModel):
    TELEGRAM_BOT_TOKEN: str
    WEBHOOK_SECRET_TOKEN: str
    SPREADSHEET_ID: str
    GOOGLE_CLIENT_EMAIL: str
    GOOGLE_PRIVATE_KEY: str  # Accepts literal newlines or \n

def load_settings() -> Settings:
    required = ["TELEGRAM_BOT_TOKEN","WEBHOOK_SECRET_TOKEN","SPREADSHEET_ID","GOOGLE_CLIENT_EMAIL","GOOGLE_PRIVATE_KEY"]
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        raise RuntimeError(f"Missing env vars: {', '.join(missing)}")

    key = os.environ["GOOGLE_PRIVATE_KEY"]
    # Normalize escaped newlines
    key = key.replace("\\n", "\n")
    return Settings(
        TELEGRAM_BOT_TOKEN=os.environ["TELEGRAM_BOT_TOKEN"],
        WEBHOOK_SECRET_TOKEN=os.environ["WEBHOOK_SECRET_TOKEN"],
        SPREADSHEET_ID=os.environ["SPREADSHEET_ID"],
        GOOGLE_CLIENT_EMAIL=os.environ["GOOGLE_CLIENT_EMAIL"],
        GOOGLE_PRIVATE_KEY=key,
    )
