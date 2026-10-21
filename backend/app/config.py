from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "development"
    database_url: str
    redis_url: str = "redis://localhost:6379/0"

    openai_api_key: str = ""
    agent_model: str = ""      # bosh = modeli parazgjedhur i SDK-së
    guard_model: str = ""      # model i vogël/i shpejtë për kontrollet
    openai_agent_model: str = "gpt-5-mini"
    openai_guard_model: str = "gpt-5-nano"

    # Ofrues alternativ OpenAI-compatible (Groq, Gemini, etj.).
    # Për OpenAI: LLM_PROVIDER=openai dhe OPENAI_API_KEY.
    llm_provider: str = "openai"
    llm_api_key: str = ""
    llm_base_url: str = ""
    llm_agent_model: str = ""
    llm_guard_model: str = ""

    embedding_model: str = ""
    embedding_dim: int = 1536

    jwt_secret: str
    access_token_minutes: int = 15
    field_encryption_keys: str = ""   # çelësa Fernet të ndarë me presje
    default_country: str = "XK"
    rate_limit_per_min: int = 20
    safe_mode: bool = False            # kill switch: vetëm L0 + mesazh statik

    # ---------------------------------------------------------------
    # Verifikimi i emailit gjatë regjistrimit (faktor i dytë).
    # Fjalëkalimi SMTP ruhet VETËM në backend/.env (shih .gitignore).
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    smtp_starttls: bool = True
    smtp_use_ssl: bool = False
    email_code_pepper: str = ""         # HMAC për hash-in e kodit; fallback: jwt_secret
    email_code_ttl_minutes: int = 10
    email_code_max_attempts: int = 5
    email_code_resend_seconds: int = 60
    email_code_max_per_hour: int = 10

    @property
    def encryption_keys(self) -> list[str]:
        return [k.strip() for k in self.field_encryption_keys.split(",") if k.strip()]

    @property
    def provider(self) -> str:
        return (self.llm_provider or "openai").strip().lower()

    @property
    def active_llm_key(self) -> str:
        if self.provider == "openai":
            return self.openai_api_key
        return self.llm_api_key

    @property
    def active_llm_base_url(self) -> str:
        if self.llm_base_url.strip():
            return self.llm_base_url.strip()
        return {
            "gemini": "https://generativelanguage.googleapis.com/v1beta/openai/",
            "groq": "https://api.groq.com/openai/v1",
        }.get(self.provider, "")

    @property
    def agent_model_name(self) -> str:
        if self.llm_agent_model:
            return self.llm_agent_model
        default = {
            "gemini": "gemini-flash-latest",
            "groq": "llama-3.3-70b-versatile",
        }.get(self.provider)
        return default or self.agent_model or self.openai_agent_model

    @property
    def guard_model_name(self) -> str:
        if self.llm_guard_model:
            return self.llm_guard_model
        default = {
            "gemini": "gemini-flash-lite-latest",
            "groq": "llama-3.1-8b-instant",
        }.get(self.provider)
        return default or self.guard_model or self.openai_guard_model

    @property
    def smtp_configured(self) -> bool:
        return bool(self.smtp_user and self.smtp_password and (self.smtp_from or self.smtp_user))


@lru_cache
def get_settings() -> Settings:
    return Settings()
