import uuid
from dataclasses import dataclass, field
from typing import Literal

from pydantic import BaseModel

TriageLevel = Literal["emergency", "urgent_today", "see_doctor_soon", "self_care"]


class TriageCard(BaseModel):
    """Kontrata midis agjentit dhe UI-së. Pa vlera parazgjedhëse (strict mode)."""
    level: TriageLevel
    title: str
    summary: str
    reasons: list[str]
    next_steps: list[str]
    watch_for: list[str]


@dataclass
class AppContext:
    """Konteksti i një ekzekutimi. Vjen NGA backend-i, kurrë nga modeli."""
    user_id: uuid.UUID
    country: str = "XK"
    locale: str = "sq"
    triage: TriageCard | None = None
    pending_actions: list[dict] = field(default_factory=list)
