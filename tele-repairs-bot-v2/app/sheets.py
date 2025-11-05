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
    # снимаем случайные внешние кавычки
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
        {
            "type": "service_account",
            "client_email": email,
            "private_key": _normalize_pkey(pkey),
            "token_uri": "https://oauth2.googleapis.com/token",
        },
        scopes=["https://www.googleapis.com/auth/spreadsheets"],
    )
    return gspread.authorize(creds)

def _open_worksheet():
    ss_id = os.getenv("SPREADSHEET_ID")
    if not ss_id:
        raise RuntimeError("SPREADSHEET_ID not set")
    gc = _client()
    ss = gc.open_by_key(ss_id)

    # 1) приоритет по GID
    gid = os.getenv("WORKSHEET_GID")
    if gid:
        try:
            target = int(gid)
            for ws in ss.worksheets():
                if getattr(ws, "id", None) == target:
                    return ws
        except Exception:
            pass

    # 2) по названию
    title = os.getenv("WORKSHEET_TITLE", "").strip()
    if title:
        try:
            return ss.worksheet(title)
        except gspread.WorksheetNotFound:
            pass

    # 3) первый лист
    return ss.get_worksheet(0)

class SheetsClient:
    def __init__(self):
        self.ws = _open_worksheet()
        self._header = [h.strip() for h in (self.ws.row_values(1) or [])]
        if not self._header:
            self._header = [
                "Date","Type","Unit","Category","Repair","Details","Vendor","Total",
                "Paid By","Paid?","Reported By","Status","Notes"
            ]
            self.ws.update("A1", [self._header])
        self._col_idx: Dict[str, int] = {name: i for i, name in enumerate(self._header) if name}

    def msgkey_exists(self, msgkey: str) -> bool:
        if "MsgKey" not in self._col_idx:
            return False
        try:
            col = self._col_idx["MsgKey"] + 1
            cell = self.ws.find(msgkey, in_column=col)
            return cell is not None
        except Exception:
            return False

    def append_repair_row(self, row: List[str]) -> None:
        data_map = dict(zip(KNOWN_FIELDS, row + [""] * max(0, len(KNOWN_FIELDS) - len(row))))
        out = ["" for _ in range(len(self._header))]
        for name, idx in self._col_idx.items():
            if name in data_map:
                out[idx] = data_map[name]
        self.ws.append_row(out, value_input_option="USER_ENTERED")
