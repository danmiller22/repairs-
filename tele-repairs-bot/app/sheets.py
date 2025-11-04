import time
from typing import Optional, Dict, Any, List
import gspread
from google.oauth2.service_account import Credentials

from .config import load_settings

_scopes = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

class SheetsClient:
    def __init__(self):
        self.settings = load_settings()
        creds_dict = self.settings.google_credentials_dict()
        creds = Credentials.from_service_account_info(creds_dict, scopes=_scopes)
        self.gc = gspread.authorize(creds)
        self.sh = self.gc.open_by_key(self.settings.SPREADSHEET_ID)

    def _get_ws(self, title: str):
        try:
            return self.sh.worksheet(title)
        except gspread.WorksheetNotFound:
            return self.sh.add_worksheet(title=title, rows=100, cols=30)

    def append_repair_row(self, row: List[str]):
        ws = self._get_ws("Repairs")
        ws.append_row(row, value_input_option="USER_ENTERED")

    def msgkey_exists(self, msg_key: str) -> bool:
        ws = self._get_ws("Repairs")
        try:
            col_values = ws.col_values(15)  # MsgKey at 15th column in our schema
        except Exception:
            return False
        return msg_key in set(col_values)

    # --- Drafts sheet ----
    def save_draft(self, chat_id: int, state: str, form: Dict[str, Any]):
        ws = self._get_ws("Drafts")
        # Try to find existing draft
        cell = None
        try:
            cell = ws.find(str(chat_id))
        except Exception:
            cell = None
        payload = {
            "state": state,
            "form": form,
            "updated_at": int(time.time()),
        }
        if cell:
            row = cell.row
            ws.update(f"A{row}:C{row}", [[chat_id, state, str(payload)]])
        else:
            ws.append_row([chat_id, state, str(payload)], value_input_option="RAW")

    def load_draft(self, chat_id: int) -> Optional[Dict[str, Any]]:
        ws = self._get_ws("Drafts")
        try:
            cell = ws.find(str(chat_id))
        except Exception:
            return None
        row = ws.row_values(cell.row)
        if len(row) < 3:
            return None
        # The third column is a str(payload). We can eval safely? No. It's our own format.
        # Accept a very simple eval-like decode using literal_eval.
        import ast
        try:
            data = ast.literal_eval(row[2])
            return data
        except Exception:
            return None

    def clear_draft(self, chat_id: int):
        ws = self._get_ws("Drafts")
        try:
            cell = ws.find(str(chat_id))
        except Exception:
            return
        ws.delete_rows(cell.row)
