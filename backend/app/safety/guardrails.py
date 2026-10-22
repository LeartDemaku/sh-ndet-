from typing import Literal

from agents import (
    Agent,
    GuardrailFunctionOutput,
    ModelSettings,
    RunContextWrapper,
    Runner,
    TResponseInputItem,
)
from pydantic import BaseModel

try:                                        # SDK i ri
    from agents.decorators import input_guardrail
except ImportError:                         # versione më të vjetra
    from agents import input_guardrail

from app.agents.prompts import GUARD_PROMPT
from app.config import get_settings


class ScopeVerdict(BaseModel):
    category: Literal["ok", "prompt_injection", "prescription_request", "harmful_misuse"]
    reason: str


_checker = Agent(
    name="Kontrolli i fushëveprimit",
    instructions=GUARD_PROMPT,
    output_type=ScopeVerdict,
    model=get_settings().guard_model_name or None,
    model_settings=ModelSettings(
        extra_body={"reasoning_effort": "none"},
        max_tokens=200,
        timeout=20.0,
    ),
)


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
    result = await Runner.run(_checker, _last_user_text(input))
    verdict = result.final_output_as(ScopeVerdict)
    return GuardrailFunctionOutput(
        output_info=verdict,
        tripwire_triggered=verdict.category != "ok",
    )
