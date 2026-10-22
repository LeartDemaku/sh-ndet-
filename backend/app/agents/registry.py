from agents import Agent, ModelSettings

from app.agents import prompts
from app.agents.context import AppContext
from app.agents.tools import (
    get_my_medications,
    propose_reminder,
    search_health_knowledge,
    submit_triage,
)
from app.config import get_settings
from app.safety.guardrails import scope_guardrail

MODEL = get_settings().agent_model_name or None   # None = modeli parazgjedhur i SDK-së

# Gemini 3.x është model "mendues" dhe pa këtë ruan 20-60 sekonda për një përgjigje
# të shkurtër. Për chat-in e shëndetësisë nuk na duhet zinxhiri i gjatë i mendimit:
# përgjigjet mbeten të shkurtra dhe të kontrolluara nga prompti + guardrail-i.
MODEL_SETTINGS = ModelSettings(
    extra_body={"reasoning_effort": "none"},
    max_tokens=1200,
    timeout=20.0,
)

symptom_agent = Agent[AppContext](
    name="Orientues simptomash",
    instructions=prompts.SYMPTOM_PROMPT,
    tools=[search_health_knowledge],
    model=MODEL,
    model_settings=MODEL_SETTINGS,
)

medication_agent = Agent[AppContext](
    name="Informues ilaçesh",
    instructions=prompts.MEDICATION_PROMPT,
    tools=[search_health_knowledge, get_my_medications],
    model=MODEL,
    model_settings=MODEL_SETTINGS,
)


def build_orchestrator(rag_enabled: bool) -> Agent[AppContext]:
    """Agjenti kryesor.

    Pa bazë njohurish të rishikuar, mjetet RAG dhe nën-agjentët thjesht shtojnë
    disa raunde modeli para përgjigjes. Në atë rast përdoret rruga e shpejtë:
    triazh/kujtesa/ilaçet direkt, pa kërkime bosh.
    """
    tools = [submit_triage, get_my_medications, propose_reminder]
    if rag_enabled:
        tools.extend([
            search_health_knowledge,
            symptom_agent.as_tool(
                tool_name="analizo_simptomat",
                tool_description="Strukturon simptomat dhe kthen pyetje shtesë dhe shenja alarmi.",
            ),
            medication_agent.as_tool(
                tool_name="info_ilaci",
                tool_description="Informacion i përgjithshëm për një ilaç (jo dozim).",
            ),
        ])
    return Agent[AppContext](
        name="Shëndet+",
        instructions=prompts.orchestrator_prompt(rag_enabled),
        tools=tools,
        input_guardrails=[scope_guardrail],
        model=MODEL,
        model_settings=MODEL_SETTINGS,
    )


orchestrator = build_orchestrator(get_settings().rag_enabled)
