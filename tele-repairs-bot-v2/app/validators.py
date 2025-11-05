from datetime import datetime
import re

def normalize_date(text: str) -> str | None:
    t = (text or "").strip().lower()
    if t in ("today","now"):
        return datetime.utcnow().date().isoformat()
    m = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})", t)
    if not m: return None
    try:
        return datetime(int(m.group(1)), int(m.group(2)), int(m.group(3))).date().isoformat()
    except ValueError:
        return None

def normalize_amount(text: str) -> str | None:
    t = (text or "").strip().replace(",", "")
    m = re.fullmatch(r"-?\d+(\.\d{1,2})?", t)
    return t if m else None
