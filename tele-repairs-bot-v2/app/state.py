from typing import Dict, Any
from .sheets import SheetsClient

class StateStore:
    def __init__(self):
        self.sheets = SheetsClient()

    def get(self, chat_id: int) -> Dict[str, Any]:
        draft = self.sheets.load_draft(chat_id) or {}
        state = draft.get("state") or "DATE"
        form = draft.get("form") or {}
        return {"state": state, "form": form}

    def set(self, chat_id: int, state: str, form: Dict[str, Any]):
        self.sheets.save_draft(chat_id, state, form)

    def clear(self, chat_id: int):
        self.sheets.clear_draft(chat_id)
