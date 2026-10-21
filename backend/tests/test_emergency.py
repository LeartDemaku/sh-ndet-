import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.safety.emergency import check_emergency, emergency_message, emergency_number

MUST_TRIGGER = [
    ("Kam dhimbje të forta në gjoks dhe më merret fryma", "emergency"),
    ("Nuk mund të marr frymë", "emergency"),
    ("Dua të vras veten", "crisis"),
    ("po më fryhet fyti pas ushqimit", "emergency"),
    ("I can't breathe", "emergency"),
]
MUST_NOT_TRIGGER = [
    "Kam dhimbje koke prej dy ditësh",
    "Nuk kam dhimbje në gjoks, vetëm kollë",
    "Sa ujë duhet të pi në ditë?",
]


@pytest.mark.parametrize("text,level", MUST_TRIGGER)
def test_emergency_detected(text, level):
    hit = check_emergency(text)
    assert hit is not None and hit.level == level


@pytest.mark.parametrize("text", MUST_NOT_TRIGGER)
def test_no_false_alarm(text):
    assert check_emergency(text) is None


def test_message_contains_official_ambulance_number():
    hit = check_emergency("kam dhimbje ne gjoks")
    assert hit is not None
    message = emergency_message(hit, "XK")
    assert emergency_number("XK") == "194"
    assert message.count("194") == 1
    assert "112" not in message


@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
