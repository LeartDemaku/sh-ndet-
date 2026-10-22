import re
from typing import Literal

from agents import (
    Agent,
    GuardrailFunctionOutput,
    RunContextWrapper,
    TResponseInputItem,
)
from pydantic import BaseModel

try:                                        # SDK i ri
    from agents.decorators import input_guardrail
except ImportError:                         # versione më të vjetra
    from agents import input_guardrail

from app.safety.emergency import normalize


class ScopeVerdict(BaseModel):
    category: Literal["ok", "prompt_injection", "prescription_request", "harmful_misuse"]
    reason: str


# Kontrolli i fushëveprimit është deterministik dhe lokal. Kështu nuk humbet
# kohë me një thirrje tjetër modeli dhe chat-i nuk bllokohet kur ofruesi i AI
# është i zënë. Rastet e urgjencës kapen më parë nga check_emergency().
_INJECTION = re.compile(
    r"\b(ignore|ignoro|harro|shperfill)\b.{0,50}"
    r"\b(udhezim\w*|instruksion\w*|rregull\w*|prompt)\b"
    r"|\b(system prompt|developer mode|jailbreak|bypass)\b"
    r"|\b(trego|reveal|show|zbulo)\b.{0,30}"
    r"\b(udhezim\w*|instruksion\w*|prompt)\b"
    r"|\b(act as|behave as)\b"
)
_PRESCRIPTION = re.compile(
    r"\brecet\w*"
    r"|\bantibiotik\w*\b.{0,50}\b(pa|me jep|jep|marr|si)\b"
    r"|\b(ndrysho|rrit|ul)\w*\s+doz\w*"
    r"|\bdoz\w*\b.{0,30}\b(sa|me jep|jep|ndrysho)\b"
)
_HARMFUL = re.compile(
    r"\b(vetevras\w*|vras veten|dua te vdes|lendoj veten|demtoj veten|"
    r"mbidoz\w*|overdose|helmim\w*|poison\w*)\b"
    r"|\bsa\b.{0,25}\b(tableta|ilace)\b.{0,25}\b(vdes|vdek|demtoj)\b"
    r"|\b(kill myself|want to die|hurt myself|end my life)\b"
)


def classify_scope(text: str) -> ScopeVerdict:
    norm = normalize(text)
    if _INJECTION.search(norm):
        return ScopeVerdict(
            category="prompt_injection",
            reason="Kërkesë për të ndryshuar ose zbuluar udhëzimet.",
        )
    if _PRESCRIPTION.search(norm):
        return ScopeVerdict(
            category="prescription_request",
            reason="Kërkesë për recetë ose ndryshim doze.",
        )
    if _HARMFUL.search(norm):
        return ScopeVerdict(
            category="harmful_misuse",
            reason="Rrezik për dëmtim ose keqpërdorim ilaçesh.",
        )
    return ScopeVerdict(category="ok", reason="Pyetje brenda fushëveprimit.")


def _last_user_text(data: str | list[TResponseInputItem]) -> str:
    if isinstance(data, str):
        return data
    for item in reversed(data):
        if isinstance(item, dict) and item.get("role") == "user":
            content = item.get("content")
            return content if isinstance(content, str) else str(content)
    return ""


@input_guardrail(run_in_parallel=False)     # bllokon: agjenti nuk niset nëse bie alarmi
async def scope_guardrail(
    ctx: RunContextWrapper, agent: Agent, input: str | list[TResponseInputItem]
) -> GuardrailFunctionOutput:
    verdict = classify_scope(_last_user_text(input))
    return GuardrailFunctionOutput(
        output_info=verdict,
        tripwire_triggered=verdict.category != "ok",
    )
