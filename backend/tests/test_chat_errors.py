from types import SimpleNamespace

from app.routers.chat import llm_error_message


def test_quota_error_is_actionable_in_development():
    exc = SimpleNamespace(code="credit_balance_exhausted", body=None)
    code, message = llm_error_message(exc, "XK", "development")
    assert code == "ai_no_credits"
    assert "kredi" in message
    assert "ofruesit" in message
    assert "194" in message
    assert "112" not in message


def test_quota_error_extracts_code_from_provider_body():
    exc = SimpleNamespace(
        code=None,
        body={"error": {"code": "insufficient_quota"}},
    )
    code, message = llm_error_message(exc, "XK", "production")
    assert code == "ai_no_credits"
    assert "OpenAI" not in message
    assert "194" in message
    assert "112" not in message


def test_other_rate_limit_uses_generic_message():
    exc = SimpleNamespace(code="rate_limit_exceeded", body=None)
    code, message = llm_error_message(exc, "XK", "production")
    assert code == "ai_unavailable"
    assert "194" in message
    assert "112" not in message
