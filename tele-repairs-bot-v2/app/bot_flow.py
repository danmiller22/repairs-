from typing import List
from datetime import datetime
from telegram import Update, ReplyKeyboardMarkup, ReplyKeyboardRemove, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import ContextTypes
from telegram.constants import ParseMode

from .validators import normalize_date, normalize_amount, looks_like_url
from .state import StateStore
from .sheets import SheetsClient

BACK = "Back"
CANCEL = "Cancel"
DONE = "Done"
SKIP = "Skip"

TYPE_CHOICES = ["Repair","PM Service","Tire","Tow","Wash","Inspection","Other"]
CATEGORY_CHOICES = ["Engine","Tires","Brakes","Electrical","Fluids/Oil","Body","Cooling","Drivetrain","DOT","Other"]
PAIDBY_CHOICES = ["Company","Driver","Warranty","Other"]
PAID_CHOICES = ["Yes","No"]
STATUS_CHOICES = ["Open","In Progress","On Hold","Closed"]

def reply_kb(buttons: List[str]) -> ReplyKeyboardMarkup:
    rows = [buttons[i:i+3] for i in range(0, len(buttons), 3)]
    rows.append([BACK, CANCEL])
    return ReplyKeyboardMarkup(rows, resize_keyboard=True, one_time_keyboard=True)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "Create a new repair record.",
        reply_markup=ReplyKeyboardMarkup([["Continue","Cancel"]], resize_keyboard=True),
    )
    context.user_data["state"] = "START"
    context.user_data["form"] = {}

async def new(update: Update, context: ContextTypes.DEFAULT_TYPE):
    ss = StateStore()
    ss.clear(update.effective_chat.id)
    context.user_data.clear()
    context.user_data["state"] = "DATE"
    context.user_data["form"] = {}
    await ask_date(update, context)

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    ss = StateStore()
    ss.clear(update.effective_chat.id)
    context.user_data.clear()
    await update.message.reply_text("Cancelled.", reply_markup=ReplyKeyboardRemove())

async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()
    if text == CANCEL:
        return await cancel(update, context)
    if text == BACK:
        return await go_back(update, context)

    state = context.user_data.get("state","DATE")
    form = context.user_data.get("form", {})

    if state == "START":
        if text.lower() == "continue":
            context.user_data["state"] = "DATE"
            return await ask_date(update, context)
        else:
            return await cancel(update, context)

    if state == "DATE":
        if text in ["Today","Pick date"]:
            if text == "Today":
                form["Date"] = normalize_date("today")
                context.user_data["state"] = "TYPE"
                return await ask_type(update, context)
            else:
                await update.message.reply_text(
                    "Type date as YYYY-MM-DD",
                    reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True),
                )
                context.user_data["state"] = "DATE_TYPED"
                return
        iso = normalize_date(text)
        if iso:
            form["Date"] = iso
            context.user_data["state"] = "TYPE"
            return await ask_type(update, context)
        await update.message.reply_text(
            "Enter date like 2025-01-31 or tap Today.",
            reply_markup=ReplyKeyboardMarkup([["Today","Pick date"], [BACK, CANCEL]], resize_keyboard=True),
        )
        return

    if state == "DATE_TYPED":
        iso = normalize_date(text)
        if iso:
            form["Date"] = iso
            context.user_data["state"] = "TYPE"
            return await ask_type(update, context)
        await update.message.reply_text(
            "Enter date like 2025-01-31.",
            reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True),
        )
        return

    if state == "TYPE":
        if text in TYPE_CHOICES:
            form["Type"] = text
            context.user_data["state"] = "UNIT"
            return await ask_unit(update, context)
        await update.message.reply_text("Choose a Type.", reply_markup=reply_kb(TYPE_CHOICES))
        return

    if state == "UNIT":
        form["Unit"] = text
        context.user_data["state"] = "CATEGORY"
        return await ask_category(update, context)

    if state == "CATEGORY":
        if text in CATEGORY_CHOICES:
            form["Category"] = text
            context.user_data["state"] = "REPAIR"
            return await ask_repair(update, context)
        await update.message.reply_text("Choose a Category.", reply_markup=reply_kb(CATEGORY_CHOICES))
        return

    if state == "REPAIR":
        form["Repair"] = text
        context.user_data["state"] = "DETAILS"
        form["Details"] = ""
        return await ask_details(update, context)

    if state == "DETAILS":
        if text == DONE:
            context.user_data["state"] = "VENDOR"
            return await ask_vendor(update, context)
        else:
            prev = form.get("Details", "").strip()
            form["Details"] = (f"{prev}\n{text.strip()}".strip() if prev else text.strip())
            await update.message.reply_text(
                "Add more details or press Done.",
                reply_markup=ReplyKeyboardMarkup([[DONE, BACK, CANCEL]], resize_keyboard=True),
            )
            return

    if state == "VENDOR":
        form["Vendor"] = text
        context.user_data["state"] = "TOTAL"
        return await ask_total(update, context)

    if state == "TOTAL":
        amt = normalize_amount(text)
        if not amt:
            await update.message.reply_text(
                "Enter a number like 300 or 300.00.",
                reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True),
            )
            return
        form["Total"] = amt
        context.user_data["state"] = "PAID_BY"
        return await ask_paid_by(update, context)

    if state == "PAID_BY":
        if text in PAIDBY_CHOICES:
            form["Paid By"] = text
            context.user_data["state"] = "PAID"
            return await ask_paid(update, context)
        await update.message.reply_text("Who paid?", reply_markup=reply_kb(PAIDBY_CHOICES))
        return

    if state == "PAID":
        if text in PAID_CHOICES:
            form["Paid?"] = text
            context.user_data["state"] = "REPORTED_BY"
            return await ask_reported_by(update, context)
        await update.message.reply_text("Is it paid?", reply_markup=reply_kb(PAID_CHOICES))
        return

    if state == "REPORTED_BY":
        if text == "Use my name":
            form["Reported By"] = update.effective_user.full_name
        else:
            form["Reported By"] = text
        context.user_data["state"] = "STATUS"
        return await ask_status(update, context)

    if state == "STATUS":
        if text in STATUS_CHOICES:
            form["Status"] = text
            context.user_data["state"] = "NOTES"
            return await ask_notes(update, context)
        await update.message.reply_text("Choose a status.", reply_markup=reply_kb(STATUS_CHOICES))
        return

    if state == "NOTES":
        if text != SKIP:
            form["Notes"] = text
        else:
            form["Notes"] = ""
        context.user_data["state"] = "INVOICE"
        return await ask_invoice(update, context)

    if state == "INVOICE":
        if text != SKIP:
            if not looks_like_url(text):
                await update.message.reply_text(
                    "Send a valid URL starting with http(s):// or tap Skip.",
                    reply_markup=ReplyKeyboardMarkup([[SKIP, BACK, CANCEL]], resize_keyboard=True),
                )
                return
            form["InvoiceLink"] = text.strip()
        else:
            form["InvoiceLink"] = ""
        context.user_data["state"] = "CONFIRM"
        return await show_confirm(update, context)

    if state == "CONFIRM":
        await update.message.reply_text("Use buttons: Save, Edit, or Cancel.")
        return

async def ask_date(update: Update, context: ContextTypes.DEFAULT_TYPE):
    kb = ReplyKeyboardMarkup([["Today","Pick date"], [BACK, CANCEL]], resize_keyboard=True)
    await update.message.reply_text("Date of the repair?", reply_markup=kb)
    await persist_state(update, context, "DATE")

async def ask_type(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Type?", reply_markup=reply_kb(TYPE_CHOICES))
    await persist_state(update, context, "TYPE")

async def ask_unit(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Truck or trailer number?", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "UNIT")

async def ask_category(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Category?", reply_markup=reply_kb(CATEGORY_CHOICES))
    await persist_state(update, context, "CATEGORY")

async def ask_repair(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Short title of the work?", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "REPAIR")

async def ask_details(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Details?", reply_markup=ReplyKeyboardMarkup([[DONE, BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "DETAILS")

async def ask_vendor(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Vendor?", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "VENDOR")

async def ask_total(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Total amount?", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "TOTAL")

async def ask_paid_by(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Who paid?", reply_markup=reply_kb(PAIDBY_CHOICES))
    await persist_state(update, context, "PAID_BY")

async def ask_paid(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Is it paid?", reply_markup=reply_kb(PAID_CHOICES))
    await persist_state(update, context, "PAID")

async def ask_reported_by(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Reported by?", reply_markup=ReplyKeyboardMarkup([["Use my name"], [BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "REPORTED_BY")

async def ask_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Status?", reply_markup=reply_kb(STATUS_CHOICES))
    await persist_state(update, context, "STATUS")

async def ask_notes(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Notes (optional).", reply_markup=ReplyKeyboardMarkup([[SKIP, BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "NOTES")

async def ask_invoice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Invoice link (optional). Send a URL or Skip.", reply_markup=ReplyKeyboardMarkup([[SKIP, BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "INVOICE")

async def show_confirm(update: Update, context: ContextTypes.DEFAULT_TYPE):
    form = context.user_data.get("form", {})
    for k in ["InvoiceLink", "Notes"]:
        form.setdefault(k, "")
    summary = (
        f"*Date:* {form.get('Date','')}\n"
        f"*Type:* {form.get('Type','')}\n"
        f"*Unit:* {form.get('Unit','')}\n"
        f"*Category:* {form.get('Category','')}\n"
        f"*Repair:* {form.get('Repair','')}\n"
        f"*Details:* {form.get('Details','')}\n"
        f"*Vendor:* {form.get('Vendor','')}\n"
        f"*Total:* {form.get('Total','')}\n"
        f"*Paid By:* {form.get('Paid By','')}\n"
        f"*Paid?:* {form.get('Paid?','')}\n"
        f"*Reported By:* {form.get('Reported By','')}\n"
        f"*Status:* {form.get('Status','')}\n"
        f"*Notes:* {form.get('Notes','')}\n"
        f"*InvoiceLink:* {form.get('InvoiceLink','')}"
    )
    kb = InlineKeyboardMarkup([[
        InlineKeyboardButton("Save", callback_data="save"),
        InlineKeyboardButton("Edit", callback_data="edit"),
        InlineKeyboardButton("Cancel", callback_data="cancel_inline"),
    ]])
    await update.message.reply_text(summary, parse_mode=ParseMode.MARKDOWN, reply_markup=kb)
    await persist_state(update, context, "CONFIRM")

async def go_back(update: Update, context: ContextTypes.DEFAULT_TYPE):
    order = ["DATE","TYPE","UNIT","CATEGORY","REPAIR","DETAILS","VENDOR","TOTAL","PAID_BY","PAID","REPORTED_BY","STATUS","NOTES","INVOICE","CONFIRM"]
    state = context.user_data.get("state","DATE")
    try:
        idx = order.index(state)
        prev_state = order[max(0, idx-1)]
    except ValueError:
        prev_state = "DATE"
    fn = {
        "DATE": ask_date,
        "TYPE": ask_type,
        "UNIT": ask_unit,
        "CATEGORY": ask_category,
        "REPAIR": ask_repair,
        "DETAILS": ask_details,
        "VENDOR": ask_vendor,
        "TOTAL": ask_total,
        "PAID_BY": ask_paid_by,
        "PAID": ask_paid,
        "REPORTED_BY": ask_reported_by,
        "STATUS": ask_status,
        "NOTES": ask_notes,
        "INVOICE": ask_invoice,
        "CONFIRM": show_confirm,
    }[prev_state]
    context.user_data["state"] = prev_state
    return await fn(update, context)

async def persist_state(update: Update, context: ContextTypes.DEFAULT_TYPE, new_state: str):
    form = context.user_data.get("form", {})
    ss = StateStore()
    ss.set(update.effective_chat.id, new_state, form)

async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    data = query.data
    await query.answer()
    if data == "cancel_inline":
        ss = StateStore()
        ss.clear(update.effective_chat.id)
        context.user_data.clear()
        await query.edit_message_text("Cancelled.")
        return
    if data == "edit":
        context.user_data["state"] = "DATE"
        await query.edit_message_text("Editing. Let's start again from Date.")
        await ask_date(update, context)
        return
    if data == "save":
        form = context.user_data.get("form", {})
        required = ["Date","Type","Unit","Category","Repair","Vendor","Total","Paid By","Paid?","Reported By","Status"]
        missing = [k for k in required if not form.get(k)]
        if missing:
            await query.edit_message_text(f"Missing fields: {', '.join(missing)}")
            return
        row = [
            form.get("Date",""),
            form.get("Type",""),
            form.get("Unit",""),
            form.get("Category",""),
            form.get("Repair",""),
            form.get("Details",""),
            form.get("Vendor",""),
            form.get("Total",""),
            form.get("Paid By",""),
            form.get("Paid?",""),
            form.get("Reported By",""),
            form.get("Status",""),
            form.get("Notes",""),
            form.get("InvoiceLink",""),
            f"{update.update_id}|{update.effective_chat.id}:{update.effective_message.message_id}",
            datetime.utcnow().isoformat(timespec="seconds")+"Z",
        ]
        sheets = SheetsClient()
        msgkey = row[14]
        if sheets.msgkey_exists(msgkey):
            await query.edit_message_text("Duplicate detected. Not saved.")
            return
        sheets.append_repair_row(row)
        ss = StateStore()
        ss.clear(update.effective_chat.id)
        context.user_data.clear()
        await query.edit_message_text("Saved ✅")
        return
