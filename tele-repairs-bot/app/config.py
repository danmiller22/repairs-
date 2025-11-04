import os
import base64
import json
from typing import List, Optional
from pydantic import BaseModel

class Settings(BaseModel):
    TELEGRAM_BOT_TOKEN: str
    WEBHOOK_SECRET_TOKEN: str
    GOOGLE_CREDENTIALS_B64: str
    SPREADSHEET_ID: str
    DRIVE_FOLDER_ID: str
    ADMIN_ID: str
    ALLOWED_CHAT_IDS: Optional[str] = None

    @property
    def allowed_chat_ids(self) -> List[int]:
        if not self.ALLOWED_CHAT_IDS:
            return []
        return [int(x.strip()) for x in self.ALLOWED_CHAT_IDS.split(",") if x.strip()]

    def google_credentials_dict(self) -> dict:
        raw = base64.b64decode(self.GOOGLE_CREDENTIALS_B64)
        return json.loads(raw)

def load_settings() -> Settings:
    missing = [k for k in [
        "TELEGRAM_BOT_TOKEN","WEBHOOK_SECRET_TOKEN","GOOGLE_CREDENTIALS_B64",
        "SPREADSHEET_ID","DRIVE_FOLDER_ID","ADMIN_ID"
    ] if not os.getenv(k)]
    if missing:
        raise RuntimeError(f"Missing env vars: {', '.join(missing)}")

    return Settings(
        TELEGRAM_BOT_TOKEN=os.environ["TELEGRAM_BOT_TOKEN"],
        WEBHOOK_SECRET_TOKEN=os.environ["WEBHOOK_SECRET_TOKEN"],
        GOOGLE_CREDENTIALS_B64=os.environ["GOOGLE_CREDENTIALS_B64"],
        SPREADSHEET_ID=os.environ["SPREADSHEET_ID"],
        DRIVE_FOLDER_ID=os.environ["DRIVE_FOLDER_ID"],
        ADMIN_ID=os.environ["ADMIN_ID"],
        ALLOWED_CHAT_IDS=os.getenv("ALLOWED_CHAT_IDS"),
    )
