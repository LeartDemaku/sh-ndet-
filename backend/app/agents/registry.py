from agents import Agent

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

MODEL = get_settings().agent_model or None   # None = modeli parazgjedhur i SDK-së

symptom_agent = Agent[AppContext](
    name="Orientues simptomash",
    instructions=prompts.SYMPTOM_PROMPT,
    tools=[search_health_knowledge],
    model=MODEL,
)

medication_agent = Agent[AppContext](
    name="Informues ilaçesh",
    instructions=prompts.MEDICATION_PROMPT,
    tools=[search_health_knowledge, get_my_medications],
    model=MODEL,
)

orchestrator = Agent[AppContext](
    name="Shëndet+",
    instructions=prompts.ORCHESTRATOR_PROMPT,
    tools=[
        submit_triage,
        get_my_medications,
        propose_reminder,
        search_health_knowledge,
        symptom_agent.as_tool(
            tool_name="analizo_simptomat",
            tool_description="Strukturon simptomat dhe kthen pyetje shtesë dhe shenja alarmi.",
        ),
        medication_agent.as_tool(
            tool_name="info_ilaci",
            tool_description="Informacion i përgjithshëm për një ilaç (jo dozim).",
        ),
    ],
    input_guardrails=[scope_guardrail],
    model=MODEL,
)
