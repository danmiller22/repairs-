import logging
import logging.config
from fastapi import FastAPI, Request, Header, HTTPException
from fastapi.responses import JSONResponse
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters

from .config import load_settings
from .bot_flow import start, new, cancel, handle_text, handle_callback

# Логи
logging.config.fileConfig('app/logging.ini', disable_existing_loggers=False)
log = logging.getLogger("uvicorn.error")

settings = load_settings()
app = FastAPI()

application: Application = Application.builder().token(settings.TELEGRAM_BOT_TOKEN).build()

# Handlers
application.add_handler(CommandHandler("start", start))
application.add_handler(CommandHandler("new", new))
application.add_handler(CommandHandler("cancel", cancel))
application.add_handler(CallbackQueryHandler(handle_callback))
application.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_text))

@app.on_event("startup")
async def on_startup():
    log.info("Starting Telegram application")
    await application.initialize()
    await application.start()
    log.info("Telegram application started")

@app.on_event("shutdown")
async def on_shutdown():
    log.info("Stopping Telegram application")
    await application.stop()
    await application.shutdown()

@app.get("/healthz")
async def healthz():
    return {"ok": True}

@app.post("/webhook/{secret}")
async def telegram_webhook(
    request: Request,
    secret: str,
    x_telegram_bot_api_secret_token: str = Header(None),
):
    # Секрет проверяем только в пути
    if secret != settings.WEBHOOK_SECRET_TOKEN:
        log.warning("Forbidden: bad path secret")
        raise HTTPException(status_code=403, detail="bad path secret")

    # Хедер только логируем, не блокируем (на Render может теряться)
    if x_telegram_bot_api_secret_token != settings.WEBHOOK_SECRET_TOKEN:
        log.warning("Header secret missing or mismatched. Got=%r", x_telegram_bot_api_secret_token)

    data = await request.json()
    log.info("Webhook update received: %s", str(data)[:500])
    update = Update.de_json(data, application.bot)
    await application.process_update(update)
    return JSONResponse({"ok": True})
