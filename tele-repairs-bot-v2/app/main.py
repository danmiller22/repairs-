import logging
from fastapi import FastAPI, Request, Header, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters

from .config import load_settings
from .bot_flow import start, new, cancel, handle_text, handle_callback, do_save

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("app")

settings = load_settings()
app = FastAPI()

# Telegram app
tg: Application = Application.builder().token(settings.TELEGRAM_BOT_TOKEN).build()
tg.add_handler(CommandHandler("start", start))
tg.add_handler(CommandHandler("new", new))
tg.add_handler(CommandHandler("cancel", cancel))
tg.add_handler(CommandHandler("save", do_save))  # текстовая альтернатива кнопке Save
tg.add_handler(CallbackQueryHandler(handle_callback, pattern="^(save|edit|cancel_inline)$"))
tg.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_text))

@app.on_event("startup")
async def on_startup():
    await tg.initialize()
    await tg.start()
    log.info("Telegram bot started")

@app.on_event("shutdown")
async def on_shutdown():
    await tg.stop()
    await tg.shutdown()

@app.get("/")
async def root():
    return PlainTextResponse("ok")

@app.get("/healthz")
async def healthz():
    return {"ok": True}

# Telegram webhook
@app.post("/webhook/{secret}")
async def telegram_webhook(request: Request, secret: str, x_telegram_bot_api_secret_token: str = Header(None)):
    if secret != settings.WEBHOOK_SECRET_TOKEN:
        raise HTTPException(status_code=403, detail="bad path secret")

    try:
        data = await request.json()
    except Exception:
        return JSONResponse({"ok": True})

    try:
        update = Update.de_json(data, tg.bot)
        await tg.process_update(update)
    except Exception as e:
        log.exception("handler error: %s", e)

    return JSONResponse({"ok": True})
