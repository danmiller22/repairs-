from fastapi import FastAPI, Request, Header, HTTPException
from fastapi.responses import JSONResponse
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters

from .config import load_settings
from .bot_flow import start, new, cancel, handle_text, handle_callback

settings = load_settings()
app = FastAPI()

application: Application = Application.builder().token(settings.TELEGRAM_BOT_TOKEN).build()

application.add_handler(CommandHandler("start", start))
application.add_handler(CommandHandler("new", new))
application.add_handler(CommandHandler("cancel", cancel))
application.add_handler(CallbackQueryHandler(handle_callback))
application.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_text))

@app.on_event("startup")
async def on_startup():
    await application.initialize()
    await application.start()

@app.on_event("shutdown")
async def on_shutdown():
    await application.stop()
    await application.shutdown()

@app.get("/healthz")
async def healthz():
    return {"ok": True}

@app.post("/webhook/{secret}")
async def telegram_webhook(request: Request, secret: str, x_telegram_bot_api_secret_token: str = Header(None)):
    if secret != settings.WEBHOOK_SECRET_TOKEN:
        raise HTTPException(status_code=403, detail="bad path secret")
    if x_telegram_bot_api_secret_token != settings.WEBHOOK_SECRET_TOKEN:
        raise HTTPException(status_code=403, detail="bad header secret")
    data = await request.json()
    update = Update.de_json(data, application.bot)
    await application.process_update(update)
    return JSONResponse({"ok": True})
