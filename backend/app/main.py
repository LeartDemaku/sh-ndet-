import logging
from contextlib import asynccontextmanager

from agents import set_default_openai_key, set_tracing_disabled
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import actions, auth, chat, profile

logging.basicConfig(level=logging.INFO)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.openai_api_key:
        set_default_openai_key(settings.openai_api_key)   # .env nuk shkon në os.environ
    set_tracing_disabled(True)   # bisedat shëndetësore nuk dërgohen te trace-et e SDK-së
    yield


app = FastAPI(
    title="Shëndet+ API",
    version="0.1.0",
    lifespan=lifespan,
    docs_url=None if settings.app_env == "production" else "/docs",
    redoc_url=None,
)
app.include_router(auth.router)
app.include_router(chat.router)
app.include_router(actions.router)
app.include_router(profile.router)   # eksport, fshirje, pëlqime (privatësia)

# Vetëm për zhvillim: Flutter Web (localhost ose telefoni në të njëjtin Wi-Fi)
# duhet CORS për të thirrur API-n. Aplikacioni mobil nuk e kërkon; në
# production ky bllok nuk aktivizohet.
if settings.app_env != "production":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=(
            r"http://(localhost|127\.0\.0\.1"
            r"|10\.\d{1,3}\.\d{1,3}\.\d{1,3}"
            r"|192\.168\.\d{1,3}\.\d{1,3}"
            r"|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(:\d+)?"
        ),
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
