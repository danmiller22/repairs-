# Telegram Repairs Bot (Render + GitHub) — Minimal, no Drive

Stack: **Python + FastAPI + python-telegram-bot + gspread**. Service Account with email + private key envs. No Drive. Invoice is an optional URL field.

## What it does
- Telegram webhook endpoint.
- Questionnaire with reply buttons and inline confirm.
- Appends to Google Sheet with schema:
  `Date | Type | Unit | Category | Repair | Details | Vendor | Total | Paid By | Paid? | Reported By | Status | Notes | InvoiceLink | MsgKey | CreatedAt`
- Draft state in `Drafts` sheet by `chat_id`.

## Google setup
1) Create a **Service Account** in Google Cloud.
2) Enable **Sheets API**.
3) Share your **Spreadsheet** with the service account email as **Editor**.
4) Get `SPREADSHEET_ID` from the sheet URL.

## Render setup
- Build: `pip install -r requirements.txt`
- Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Environment variables:
  - `TELEGRAM_BOT_TOKEN`
  - `WEBHOOK_SECRET_TOKEN`
  - `SPREADSHEET_ID`
  - `GOOGLE_CLIENT_EMAIL`
  - `GOOGLE_PRIVATE_KEY`  (include literal newlines or use \n; the app normalizes)

## Set Telegram webhook
```
curl -X POST "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook"   -H "X-Telegram-Bot-Api-Secret-Token: <WEBHOOK_SECRET_TOKEN>"   -d "url=https://<render-service>.onrender.com/webhook/<WEBHOOK_SECRET_TOKEN>&drop_pending_updates=true"
```

## Test
- Visit `/healthz` → should return `{"ok": true}`.
- DM `/new` to the bot and complete the flow.
