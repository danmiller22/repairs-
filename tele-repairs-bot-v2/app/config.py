import os
from dataclasses import dataclass

@dataclass
class Settings:
    TELEGRAM_BOT_TOKEN: str
    WEBHOOK_SECRET_TOKEN: str

def load_settings() -> Settings:
    return Settings(
        TELEGRAM_BOT_TOKEN=os.environ["TELEGRAM_BOT_TOKEN"],
        WEBHOOK_SECRET_TOKEN=os.environ["WEBHOOK_SECRET_TOKEN"],
    )
