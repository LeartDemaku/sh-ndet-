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


def test_gemini_defaults_need_only_provider_and_key():
    settings = _settings(llm_provider="gemini", llm_api_key="gm-test")
    assert settings.active_llm_base_url.endswith("/v1beta/openai/")
    assert settings.agent_model_name == "gemini-flash-latest"
    assert settings.guard_model_name == "gemini-flash-lite-latest"


def test_groq_defaults_need_only_provider_and_key():
    settings = _settings(
        llm_provider="groq",
        llm_api_key="gsk-test",
        agent_model="gpt-5-mini",
        guard_model="gpt-5-nano",
    )
    assert settings.active_llm_base_url == "https://api.groq.com/openai/v1"
    assert settings.agent_model_name == "llama-3.3-70b-versatile"
    assert settings.guard_model_name == "llama-3.1-8b-instant"


def test_explicit_llm_models_override_provider_defaults():
    settings = _settings(
        llm_provider="groq",
        llm_agent_model="custom-agent",
        llm_guard_model="custom-guard",
    )
    assert settings.agent_model_name == "custom-agent"
    assert settings.guard_model_name == "custom-guard"


def test_provider_name_is_normalized():
    settings = _settings(llm_provider=" Gemini ")
    assert settings.provider == "gemini"
