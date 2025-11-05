from typing import List
from datetime import datetime
from telegram import Update, ReplyKeyboardMarkup, ReplyKeyboardRemove, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import ContextTypes

from .validators import normalize_date, normalize_amount
from .state import StateStore
from .sheets import SheetsClient

BACK, CANCEL, DONE, SKIP = "Back", "Cancel", "Done", "Skip"

TYPE_CHOICES = ["Repair","PM Service","Tire","Tow","Wash","Inspection","Other"]
CATEGORY_CHOICES = ["Engine","Tires","Brakes","Electrical","Fluids/Oil","Body","Cooling","Drivetrain","DOT","Other"]
PAIDBY_CHOICES = ["Company","Driver","Warranty","Other"]
PAID_CHOICES = ["Yes","No"]
STATUS_CHOICES = ["Open","In Progress","On Hold","Closed"]
UNIT_TYPE_CHOICES = ["Truck","Trailer"]

def reply_kb(buttons: List[str]) -> ReplyKeyboardMarkup:
    rows = [buttons[i:i+3] for i in range(0, len(buttons), 3)]
    rows.append([BACK, CANCEL])
    return ReplyKeyboardMarkup(rows, resize_keyboard=True, one_time_keyboard=True)

def _hydrate_from_store(update: Update, context: ContextTypes.DEFAULT_TYPE):
    ss = StateStore()
    saved = None
    try:
        saved = ss.get(update.effective_chat.id)
    except Exception:
        pass
    if isinstance(saved, tuple) and len(saved) == 2:
        state, form = saved
    elif isinstance(saved, dict):
        state, form = saved.get("state"), saved.get("form")
    else:
        state = form = None
    if form and not context.user_data.get("form"):
        context.user_data["form"] = form
    if state and not context.user_data.get("state"):
        context.user_data["state"] = state

def _unit_label(form: dict) -> str:
    return "truck" if (form or {}).get("UnitType") == "TRK" else "trailer" if (form or {}).get("UnitType") == "TRL" else "unit"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Create a new repair record.", reply_markup=ReplyKeyboardMarkup([["Continue","Cancel"]], resize_keyboard=True))
    context.user_data["state"] = "START"
    context.user_data["form"] = {}

async def new(update: Update, context: ContextTypes.DEFAULT_TYPE):
    StateStore().clear(update.effective_chat.id)
    context.user_data.clear()
    context.user_data["state"] = "DATE"
    context.user_data["form"] = {}
    await ask_date(update, context)

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    StateStore().clear(update.effective_chat.id)
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
        return await cancel(update, context)

    if state == "DATE":
        if text == "Today":
            form["Date"] = normalize_date("today")
            context.user_data["state"] = "TYPE"
            return await ask_type(update, context)
        if text == "Pick date":
            await update.message.reply_text("Type date as YYYY-MM-DD", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
            context.user_data["state"] = "DATE_TYPED"
            return
        iso = normalize_date(text)
        if iso:
            form["Date"] = iso
            context.user_data["state"] = "TYPE"
            return await ask_type(update, context)
        await update.message.reply_text("Enter date like 2025-01-31 or tap Today.", reply_markup=ReplyKeyboardMarkup([["Today","Pick date"], [BACK, CANCEL]], resize_keyboard=True))
        return

    if state == "DATE_TYPED":
        iso = normalize_date(text)
        if iso:
            form["Date"] = iso
            context.user_data["state"] = "TYPE"
            return await ask_type(update, context)
        await update.message.reply_text("Enter date like 2025-01-31.", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
        return

    if state == "TYPE":
        # принимаем любое значение типом
        if text:
            form["Type"] = text
            context.user_data["form"] = form
            context.user_data["state"] = "UNIT_TYPE"
            return await ask_unit_type(update, context)
        await update.message.reply_text("Choose a Type.", reply_markup=reply_kb(TYPE_CHOICES))
        return

    if state == "UNIT_TYPE":
        t = text.strip().lower()
        if t in ["truck","trailer"]:
            form["UnitType"] = "TRK" if t == "truck" else "TRL"
            context.user_data["form"] = form
            context.user_data["state"] = "UNIT_NUMBER"
            return await ask_unit_number(update, context)
        await update.message.reply_text("Choose: Truck or Trailer.", reply_markup=reply_kb(UNIT_TYPE_CHOICES))
        return

    if state == "UNIT_NUMBER":
        num = text.replace("TRK","").replace("TRL","").strip()
        if not num:
            await update.message.reply_text(f"Enter {_unit_label(form)} number.", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
            return
        if form.get("UnitType") == "TRK":
            form["Unit"] = f"TRK {num}"
            context.user_data["state"] = "CATEGORY"
            return await ask_category(update, context)
        form["TrailerNum"] = num
        context.user_data["state"] = "TRAILER_TRUCK"
        return await ask_trailer_truck(update, context)

    if state == "TRAILER_TRUCK":
        trk = text.replace("TRK","").strip()
        if not trk:
            await update.message.reply_text("Trailer linked to which truck number? e.g. 2621.", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
            return
        form["Unit"] = f"TRL {form.get('TrailerNum','').strip()} ( TRK {trk} )"
        form.pop("TrailerNum", None)
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
        prev = form.get("Details","").strip()
        form["Details"] = (f"{prev}\n{text.strip()}".strip() if prev else text.strip())
        await update.message.reply_text("Add more details or press Done.", reply_markup=ReplyKeyboardMarkup([[DONE, BACK, CANCEL]], resize_keyboard=True))
        return

    if state == "VENDOR":
        form["Vendor"] = text
        context.user_data["state"] = "TOTAL"
        return await ask_total(update, context)

    if state == "TOTAL":
        amt = normalize_amount(text)
        if not amt:
            await update.message.reply_text("Enter a number like 300 or 300.00.", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
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
        form["Reported By"] = update.effective_user.full_name if text == "Use my name" else text
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
        form["Notes"] = "" if text == SKIP else text
        context.user_data["state"] = "CONFIRM"
        return await show_confirm(update, context)

    if state == "CONFIRM":
        if text.lower() == "save":
            return await do_save(update, context)
        if text.lower() == "edit":
            context.user_data["state"] = "DATE"
            await update.message.reply_text("Editing. Let's start again from Date.")
            return await ask_date(update, context)
        if text.lower() == "cancel":
            return await cancel(update, context)
        await update.message.reply_text("Use buttons: Save, Edit, or Cancel.")
        return

# ask* helpers
async def ask_date(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Date of the repair?", reply_markup=ReplyKeyboardMarkup([["Today","Pick date"], [BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "DATE")

async def ask_type(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Type?", reply_markup=reply_kb(TYPE_CHOICES))
    await persist_state(update, context, "TYPE")

async def ask_unit_type(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Unit type?", reply_markup=reply_kb(UNIT_TYPE_CHOICES))
    await persist_state(update, context, "UNIT_TYPE")

async def ask_unit_number(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(f"Enter {_unit_label(context.user_data.get('form', {}))} number.", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "UNIT_NUMBER")

async def ask_trailer_truck(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Trailer linked to which truck number?", reply_markup=ReplyKeyboardMarkup([[BACK, CANCEL]], resize_keyboard=True))
    await persist_state(update, context, "TRAILER_TRUCK")

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

async def show_confirm(update: Update, context: ContextTypes.DEFAULT_TYPE):
    f = context.user_data.get("form", {})
    f.setdefault("Notes", "")
    summary = (
        "Confirm:\n"
        f"Date: {f.get('Date','')}\n"
        f"Type: {f.get('Type','')}\n"
        f"Unit: {f.get('Unit','')}\n"
        f"Category: {f.get('Category','')}\n"
        f"Repair: {f.get('Repair','')}\n"
        f"Details: {f.get('Details','')}\n"
        f"Vendor: {f.get('Vendor','')}\n"
        f"Total: {f.get('Total','')}\n"
        f"Paid By: {f.get('Paid By','')}\n"
        f"Paid?: {f.get('Paid?','')}\n"
        f"Reported By: {f.get('Reported By','')}\n"
        f"Status: {f.get('Status','')}\n"
        f"Notes: {f.get('Notes','')}\n"
    )
    kb = InlineKeyboardMarkup([[
        InlineKeyboardButton("Save", callback_data="save"),
        InlineKeyboardButton("Edit", callback_data="edit"),
        InlineKeyboardButton("Cancel", callback_data="cancel_inline"),
    ]])
    await update.message.reply_text(summary, reply_markup=kb)
    await persist_state(update, context, "CONFIRM")

async def go_back(update: Update, context: ContextTypes.DEFAULT_TYPE):
    order = ["DATE","TYPE","UNIT_TYPE","UNIT_NUMBER","TRAILER_TRUCK","CATEGORY","REPAIR","DETAILS","VENDOR","TOTAL","PAID_BY","PAID","REPORTED_BY","STATUS","NOTES","CONFIRM"]
    st = context.user_data.get("state","DATE")
    idx = order.index(st) if st in order else 0
    prev = order[max(0, idx-1)]
    m = {
        "DATE": ask_date, "TYPE": ask_type, "UNIT_TYPE": ask_unit_type, "UNIT_NUMBER": ask_unit_number,
        "TRAILER_TRUCK": ask_trailer_truck, "CATEGORY": ask_category, "REPAIR": ask_repair, "DETAILS": ask_details,
        "VENDOR": ask_vendor, "TOTAL": ask_total, "PAID_BY": ask_paid_by, "PAID": ask_paid,
        "REPORTED_BY": ask_reported_by, "STATUS": ask_status, "NOTES": ask_notes, "CONFIRM": show_confirm,
    }[prev]
    context.user_data["state"] = prev
    return await m(update, context)

async def persist_state(update: Update, context: ContextTypes.DEFAULT_TYPE, new_state: str):
    StateStore().set(update.effective_chat.id, new_state, context.user_data.get("form", {}))

# --- callbacks + save ---
async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    _hydrate_from_store(update, context)
    q = update.callback_query
    data = (q.data or "").lower()
    await q.answer()
    if data == "cancel_inline":
        StateStore().clear(update.effective_chat.id); context.user_data.clear()
        try: await q.edit_message_text("Cancelled.")
        except Exception: await q.message.reply_text("Cancelled.")
        return
    if data == "edit":
        context.user_data["state"] = "DATE"
        try: await q.edit_message_text("Editing. Let's start again from Date.")
        except Exception: await q.message.reply_text("Editing. Let's start again from Date.")
        await ask_date(update, context); return
    if data == "save":
        try: await q.edit_message_text("Saving…")
        except Exception: await q.message.reply_text("Saving…")
        await do_save(update, context)

async def do_save(update: Update, context: ContextTypes.DEFAULT_TYPE):
    _hydrate_from_store(update, context)
    f = context.user_data.get("form", {}) or {}
    if not f.get("Date"): f["Date"] = normalize_date("today")
    if not f.get("Type"): f["Type"] = "Other"
    context.user_data["form"] = f
    StateStore().set(update.effective_chat.id, context.user_data.get("state","CONFIRM"), f)

    required = ["Date","Type","Unit","Category","Repair","Vendor","Total","Paid By","Paid?","Reported By","Status"]
    miss = [k for k in required if not f.get(k)]
    if miss:
        msg = "Missing fields: " + ", ".join(miss)
        if getattr(update, "callback_query", None):
            await update.callback_query.message.reply_text(msg)
        else:
            await update.message.reply_text(msg)
        return

    row = [
        f.get("Date",""), f.get("Type",""), f.get("Unit",""), f.get("Category",""),
        f.get("Repair",""), f.get("Details",""), f.get("Vendor",""), f.get("Total",""),
        f.get("Paid By",""), f.get("Paid?",""), f.get("Reported By",""), f.get("Status",""),
        f.get("Notes",""), "", f"{update.update_id}|{update.effective_chat.id}:{getattr(update.effective_message,'message_id','0')}",
        datetime.utcnow().isoformat(timespec="seconds")+"Z",
    ]
    try:
        SheetsClient().append_repair_row(row)
    except Exception as e:
        txt = f"Sheets error: {type(e).__name__}: {e}"
        if getattr(update, "callback_query", None):
            await update.callback_query.message.reply_text(txt)
        else:
            await update.message.reply_text(txt)
        return

    StateStore().clear(update.effective_chat.id); context.user_data.clear()
    if getattr(update, "callback_query", None):
        await update.callback_query.message.reply_text("Saved ✅")
    else:
        await update.message.reply_text("Saved ✅")
