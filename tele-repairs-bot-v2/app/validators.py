from datetime import datetime, date
import re
from typing import Optional

def normalize_date(s: str) -> Optional[str]:
    s = s.strip()
    if s.lower() == "today":
        return date.today().isoformat()
    try:
        d = datetime.strptime(s, "%Y-%m-%d").date()
        return d.isoformat()
    except ValueError:
        return None

_amount_re = re.compile(r"[\s\$]")

def normalize_amount(s: str) -> Optional[str]:
    s = s.strip()
    s = _amount_re.sub("", s)
    s = s.replace(",", ".")
    try:
        return f"{float(s):.2f}"
    except ValueError:
        return None

_url_re = re.compile(r"^https?://", re.IGNORECASE)

def looks_like_url(s: str) -> bool:
    return bool(_url_re.match(s.strip()))
