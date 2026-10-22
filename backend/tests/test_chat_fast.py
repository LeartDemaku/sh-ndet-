from app.health_fast_answers import fast_health_answer, offline_answer
from app.routers.chat import _fast_reply


def test_greeting_gets_instant_reply_without_model():
    reply = _fast_reply("Përshëndetje!")
    assert reply is not None
    assert "Përshëndetje" in reply
    assert "194" not in reply
    assert "112" not in reply


def test_thanks_gets_instant_reply():
    assert _fast_reply("Faleminderit") == "Me kënaqësi! Nëse ke pyetje tjetër, jam këtu."


def test_health_message_is_not_fast_pathed():
    assert _fast_reply("Përshëndetje, kam dhimbje gjoksi") is None
    assert _fast_reply("Kam ethe 38.5") is None


def test_flu_vaccine_question_gets_instant_safe_answer():
    reply = fast_health_answer(
        "Çfarë më sugjeron për vaksinën kundër gripit sezonal që është hapur "
        "në Kosovë në tetor 2026, a të vaksinohem?"
    )
    assert reply is not None
    assert "vaksin" in reply.lower()
    assert "mjek" in reply.lower()
    assert "194" not in reply
    assert "112" not in reply


def test_common_fever_question_gets_instant_answer():
    reply = fast_health_answer("Kam ethe 38.5 që nga mbrëmë")
    assert reply is not None
    assert "temperatur" in reply.lower()
    assert "112" not in reply


def test_offline_fallback_is_safe_and_actionable():
    reply = offline_answer("Një pyetje e panjohur për shëndetin")
    assert "194" in reply
    assert "112" not in reply
    assert "AI" in reply


def test_greeting_is_not_treated_as_health_fast_answer():
    assert fast_health_answer("Përshëndetje") is None
