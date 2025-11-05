import os
from typing import List, Dict
import gspread
from google.oauth2.service_account import Credentials

KNOWN_FIELDS = [
    "Date","Type","Unit","Category","Repair","Details","Vendor","Total",
    "Paid By","Paid?","Reported By","Status","Notes","InvoiceLink","MsgKey","CreatedAt"
]

def _normalize_pkey(pkey: str) -> str:
    p = (pkey or "").strip()
    if (p.startswith('"') and p.endswith('"')) or (p.startswith("'") and p.endswith("'")):
        p = p[1:-1]
    p = p.replace("\\n", "\n")
    if "PRIVATE KEY" not in p:
        raise RuntimeError("GOOGLE_PRIVATE_KEY not valid PEM")
    return p

def _client() -> gspread.Client:
    email = os.getenv("GOOGLE_CLIENT_EMAIL")
    pkey = os.getenv("GOOGLE_PRIVATE_KEY")
    if not email or not pkey:
        raise RuntimeError("GOOGLE_CLIENT_EMAIL or GOOGLE_PRIVATE_KEY not set")
    creds = Credentials.from_service_account_info(
        {"type": "service_account", "client_email": email, "private_key": _normalize_pkey(pkey),
         "token_uri": "https://oauth2.googleapis.com/token"},
        scopes=["https://www.googleapis.com/auth/spreadsheets"],
    )
    return gspread.authorize(creds)

def _open_ws():
    ss_id = os.getenv("SPREADSHEET_ID")
    if not ss_id: raise RuntimeError("SPREADSHEET_ID not set")
    ss = _client().open_by_key(ss_id)
    gid = os.getenv("WORKSHEET_GID")
    if gid:
        target = int(gid)
        for ws in ss.worksheets():
            if getattr(ws, "id", None) == target:
                return ws
    title = os.getenv("WORKSHEET_TITLE", "").strip()
    if title:
        try: return ss.worksheet(title)
        except gspread.WorksheetNotFound: pass
    return ss.get_worksheet(0)

class SheetsClient:
    def __init__(self):
        self.ws = _open_ws()
        self._header = [h.strip() for h in (self.ws.row_values(1) or [])]
        if not self._header:
            self._header = ["Date","Type","Unit","Category","Repair","Details","Vendor","Total","Paid By","Paid?","Reported By","Status","Notes"]
            self.ws.update("A1", [self._header])
        self._col_idx: Dict[str, int] = {name: i for i, name in enumerate(self._header) if name}

    def append_repair_row(self, row: List[str]) -> None:
        data = dict(zip(KNOWN_FIELDS, row + [""] * max(0, len(KNOWN_FIELDS) - len(row))))
        out = ["" for _ in range(len(self._header))]
        for name, idx in self._col_idx.items():
            if name in data: out[idx] = data[name]
        self.ws.append_row(out, value_input_option="USER_ENTERED")
