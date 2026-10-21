import json
import re

from agents import RunContextWrapper, function_tool
from sqlalchemy import select

from app.agents.context import AppContext, TriageCard
from app.crypto import decrypt
from app.db import SessionLocal
from app.models import Medication, Reminder
from app.services.rag import search_knowledge

HHMM = re.compile(r"([01]\d|2[0-3]):[0-5]\d")


@function_tool
async def submit_triage(ctx: RunContextWrapper[AppContext], card: TriageCard) -> str:
    """Regjistro kartën e triazhit që do t'i shfaqet përdoruesit.
    Thirre sa herë që vlerëson urgjencën e simptomave."""
    card.title = card.title[:80]
    card.summary = card.summary[:400]
    card.reasons = [r[:160] for r in card.reasons[:5]]
    card.next_steps = [s[:160] for s in card.next_steps[:5]] or ["Flit me një mjek."]
    card.watch_for = [w[:160] for w in card.watch_for[:5]]
    ctx.context.triage = card
    return "Karta e triazhit u regjistrua."


@function_tool
async def get_my_medications(ctx: RunContextWrapper[AppContext]) -> str:
    """Kthen ilaçet aktive të përdoruesit dhe orarët e kujtesave. Nuk jep doza."""
    uid = ctx.context.user_id                      # NGA konteksti, jo nga modeli
    stmt = (
        select(Medication.name_enc, Reminder.at_time)
        .join(Reminder, Reminder.medication_id == Medication.id, isouter=True)
        .where(Medication.user_id == uid, Medication.active.is_(True))
    )
    async with SessionLocal() as db:
        rows = (await db.execute(stmt)).all()
    meds: dict[str, list[str]] = {}
    for name_enc, at in rows:
        times = meds.setdefault(decrypt(name_enc), [])
        if at is not None:
            times.append(at.strftime("%H:%M"))
    return json.dumps(meds, ensure_ascii=False)


@function_tool
async def search_health_knowledge(ctx: RunContextWrapper[AppContext], query: str) -> str:
    """Kërko në bazën e njohurive të rishikuar klinikisht. Kthen copëza me burimin."""
    hits = await search_knowledge(query, lang=ctx.context.locale, k=4)
    if not hits:
        return "Nuk u gjet burim i besueshëm për këtë pyetje."
    return json.dumps(hits, ensure_ascii=False)


@function_tool
async def propose_reminder(
    ctx: RunContextWrapper[AppContext], medication_name: str, times: list[str]
) -> str:
    """Propozo kujtesë ilaçi (orare në formatin HH:MM). Nuk krijohet pa konfirmimin e
    përdoruesit në aplikacion."""
    valid = [t for t in times if HHMM.fullmatch(t)]
    if not valid:
        return "Orare të pavlefshme. Kërko nga përdoruesi orare si 08:00."
    ctx.context.pending_actions.append(
        {"type": "create_reminder", "medication": medication_name.strip()[:80], "times": valid}
    )
    return "Propozimi u përgatit; pret konfirmimin e përdoruesit."
