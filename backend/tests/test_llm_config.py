from app.config import Settings


def _settings(**overrides) -> Settings:
    values = {
        "database_url": "postgresql+asyncpg://test:test@localhost/test",
        "jwt_secret": "x" * 32,
        "_env_file": None,
    }
    values.update(overrides)
    return Settings(**values)


def test_openai_is_the_default_provider():
    settings = _settings(openai_api_key="sk-test", agent_model="", guard_model="")
    assert settings.provider == "openai"
    assert settings.active_llm_key == "sk-test"
    assert settings.agent_model_name == "gpt-5-mini"
    assert settings.guard_model_name == "gpt-5-nano"


def test_custom_provider_uses_its_own_key_and_models():
    settings = _settings(
        llm_provider="gemini",
        openai_api_key="sk-openai",
        llm_api_key="gm-test",
        llm_base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
        llm_agent_model="gemini-flash-latest",
        llm_guard_model="gemini-flash-lite-latest",
    )
    assert settings.provider == "gemini"
    assert settings.active_llm_key == "gm-test"
    assert settings.active_llm_base_url.endswith("/openai/")
    assert settings.agent_model_name == "gemini-flash-latest"
    assert settings.guard_model_name == "gemini-flash-lite-latest"


def test_custom_provider_falls_back_to_generic_model_overrides():
    settings = _settings(
        llm_provider="groq",
        agent_model="llama-3.3-70b-versatile",
        guard_model="llama-3.1-8b-instant",
    )
    assert settings.agent_model_name == "llama-3.3-70b-versatile"
    assert settings.guard_model_name == "llama-3.1-8b-instant"


def test_provider_name_is_normalized():
    settings = _settings(llm_provider=" Gemini ")
    assert settings.provider == "gemini"
