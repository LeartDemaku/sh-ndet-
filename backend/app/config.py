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
    def smtp_configured(self) -> bool:
        return bool(self.smtp_user and self.smtp_password and (self.smtp_from or self.smtp_user))


@lru_cache
def get_settings() -> Settings:
    return Settings()
