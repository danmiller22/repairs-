import os
from typing import List, Dict
import gspread
from google.oauth2.service_account import Credentials

# Поля, которые мы умеем писать. Порядок не важен.
KNOWN_FIELDS = [
    "Date","Type","Unit","Category","Repair","Details","Vendor","Total",
    "Paid By","Paid?","Reported By","Status","Notes","InvoiceLink","MsgKey","CreatedAt"
]

def _client() -> gspread.Client:
    email = os.getenv("GOOGLE_CLIENT_EMAIL")
    pkey = os.getenv("GOOGLE_PRIVATE_KEY")
    if not email or not pkey:
        raise RuntimeError("GOOGLE_CLIENT_EMAIL or GOOGLE_PRIVATE_KEY not set")

    # Нормализуем переносы
    pkey = pkey.replace("\\n", "\n")
    creds = Credentials.from_service_account_info({
        "type": "service_account",
        "client_email": email,
        "private_key": pkey,
        "token_uri": "https://oauth2.googleapis.com/token",
    }, scopes=[
        "https://www.googleapis.com/auth/spreadsheets"
    ])
    return gspread.authorize(creds)

def _open_worksheet():
    ss_id = os.getenv("SPREADSHEET_ID")
    if not ss_id:
        raise RuntimeError("SPREADSHEET_ID not set")
    gc = _client()
    ss = gc.open_by_key(ss_id)

    # Пытаемся открыть лист "Repairs", иначе берём первый
    try:
        ws = ss.worksheet("Repairs")
    except gspread.WorksheetNotFound:
        ws = ss.get_worksheet(0)
    return ws

class SheetsClient:
    def __init__(self):
        self.ws = _open_worksheet()
        self._header = [h.strip() for h in (self.ws.row_values(1) or [])]
        # Карту "имя колонки -> индекс" держим в памяти
        self._col_idx: Dict[str, int] = {name: i for i, name in enumerate(self._header) if name}

    def _ensure_header(self):
        # Если шапка пустая — создадим из известных полей по минимуму
        if not self._header:
            self._header = [
                "Date","Type","Unit","Category","Repair","Details","Vendor","Total",
                "Paid By","Paid?","Reported By","Status","Notes"
            ]
            self.ws.update("A1", [self._header])
            self._col_idx = {name: i for i, name in enumerate(self._header)}

    def msgkey_exists(self, msgkey: str) -> bool:
        # Если колонки MsgKey нет — считаем, что не существует (без дедупа)
        if "MsgKey" not in self._col_idx:
            return False
        col = self._col_idx["MsgKey"] + 1  # 1-based
        try:
            cell = self.ws.find(msgkey, in_column=col)
            return cell is not None
        except gspread.exceptions.APIError:
            # Иногда find падает из-за размеров. В этом случае — без дедупа.
            return False
        except gspread.exceptions.CellNotFound:
            return False

    def append_repair_row(self, row: List[str]) -> None:
        """
        row — это фиксированный список значений в порядке KNOWN_FIELDS.
        Мы перепакуем его в массив длиной по текущей шапке и запишем только известные колонки.
        """
        self._ensure_header()

        # Строим словарь поле->значение
        data_map = dict(zip(KNOWN_FIELDS, row + [""] * max(0, len(KNOWN_FIELDS) - len(row))))

        # Формируем строку строго под существующую шапку
        out = ["" for _ in range(len(self._header))]
        for name, idx in self._col_idx.items():
            if name in data_map:
                out[idx] = data_map[name]

        # Пишем как USER_ENTERED, чтобы числа и даты красиво легли
        self.ws.append_row(out, value_input_option="USER_ENTERED")
