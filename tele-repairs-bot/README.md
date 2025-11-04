# Telegram Repairs Bot (Render + GitHub)

Fast, simple, production-ready: **Python + FastAPI + python-telegram-bot + gspread + Google Drive API**.

## What it does
- Webhook endpoint for Telegram.
- Questionnaire with reply buttons, inline confirm.
- Appends a row to your Google Sheet:
  `Date | Type | Unit | Category | Repair | Details | Vendor | Total | Paid By | Paid? | Reported By | Status | Notes | InvoiceLink | MsgKey | CreatedAt`
- Optional invoice photo is uploaded to Drive; public link is stored in `InvoiceLink`.
- Drafts are stored in a `Drafts` sheet by `chat_id`.

## Prepare Google
1) Create a **Service Account** in Google Cloud.
2) Enable **Sheets API** and **Drive API**.
3) Share your **Spreadsheet** and **Drive folder** with the service account email as **Editor**.
4) Get IDs:
   - `SPREADSHEET_ID` (from the URL of the sheet)
   - `DRIVE_FOLDER_ID`

## Render setup
- Create a **Web Service** from this repo.
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- **Environment variables:**
  - `TELEGRAM_BOT_TOKEN`
  - `WEBHOOK_SECRET_TOKEN` (any long random token; used in path and header)
  - `GOOGLE_CREDENTIALS_B64` (base64 of the JSON key of the service account)
  - `SPREADSHEET_ID`
  - `DRIVE_FOLDER_ID`
  - `ADMIN_ID` (your Telegram numeric id)
  - `ALLOWED_CHAT_IDS` (optional, CSV of allowed chat ids)

## Set the Telegram webhook
Replace placeholders and run once:
```
curl -X POST "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook"   -H "X-Telegram-Bot-Api-Secret-Token: <WEBHOOK_SECRET_TOKEN>"   -d "url=https://<render-service>.onrender.com/webhook/<WEBHOOK_SECRET_TOKEN>&drop_pending_updates=true"
```

## Test
- DM the bot `/new`.
- Walk through the questionnaire.
- Check the new row in your sheet.
