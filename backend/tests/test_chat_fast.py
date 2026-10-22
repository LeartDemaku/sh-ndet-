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
