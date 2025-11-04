import logging
import os
from fastapi import FastAPI, Request, Header, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters

from .config import load_settings
from .bot_flow import start, new, cancel, handle_text, handle_callback

# Логи без внешних ini, чтобы ничего не ломало запуск
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("app")

settings = load_settings()
app = FastAPI()

# Telegram Application
tg: Application = Application.builder().token(settings.TELEGRAM_BOT_TOKEN).build()
tg.add_handler(CommandHandler("start", start))
tg.add_handler(CommandHandler("new", new))
tg.add_handler(CommandHandler("cancel", cancel))
tg.add_handler(CallbackQueryHandler(handle_callback))
tg.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_text))

@app.on_event("startup")
async def on_startup():
    log.info("Starting Telegram application")
    await tg.initialize()
    await tg.start()
    log.info("Telegram application started")

@app.on_event("shutdown")
async def on_shutdown():
    log.info("Stopping Telegram application")
    await tg.stop()
    await tg.shutdown()

@app.get("/")
async def root():
    return PlainTextResponse("ok")

@app.get("/healthz")
async def healthz():
    return {"ok": True}

@app.post("/webhook/{secret}")
async def telegram_webhook(
    request: Request,
    secret: str,
    x_telegram_bot_api_secret_token: str = Header(None),
):
    # Проверяем только секрет в пути
    if secret != settings.WEBHOOK_SECRET_TOKEN:
        log.warning("403 bad path secret: got=%r", secret)
        raise HTTPException(status_code=403, detail="bad path secret")

    # Хедер не обязателен, только логируем
    if x_telegram_bot_api_secret_token != settings.WEBHOOK_SECRET_TOKEN:
        log.warning("Header secret mismatch: got=%r", x_telegram_bot_api_secret_token)

    try:
        data = await request.json()
    except Exception as e:
        log.exception("Bad JSON: %s", e)
        return JSONResponse({"ok": True})

    try:
        log.info("Update: %s", str(data)[:600])
        update = Update.de_json(data, tg.bot)
        await tg.process_update(update)
    except Exception as e:
        log.exception("Handler error: %s", e)

    return JSONResponse({"ok": True})
