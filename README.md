# Shëndet+

**Aplikacion shëndetësor me agjentë AI** — nga ideja te produkti për përdorim masiv.
Udhëzues teknik / 02 · Python · FastAPI · Agents SDK · PostgreSQL · Flutter.

> ⚠️ **Njoftim i rëndësishëm.** Ky projekt është ndërtuar sipas udhëzuesit teknik edukativ
> "Health AI Agent App". Aplikacioni jep **informacion të përgjithshëm shëndetësor dhe orientim
> për kërkimin e ndihmës**. Nuk vendos diagnoza, nuk përshkruan terapi dhe nuk e zëvendëson
> mjekun. Para çdo publikimi me përdorues realë nevojiten rishikim klinik, rishikim ligjor
> (privatësia dhe pajisjet mjekësore), test sigurie dhe pëlqimet e duhura.

## Struktura

```
Shëndet+/
├── backend/                # FastAPI + agjentët AI (Python)
│   ├── app/
│   │   ├── main.py         # aplikacioni FastAPI
│   │   ├── config.py       # cilësimet nga .env
│   │   ├── db.py           # lidhja me PostgreSQL
│   │   ├── models.py       # tabelat (SQLAlchemy)
│   │   ├── crypto.py       # enkriptim në fushë (Fernet)
│   │   ├── security.py     # fjalëkalime (argon2) + JWT
│   │   ├── deps.py         # get_current_user
│   │   ├── ratelimit.py    # kufizim kërkesash (Redis)
│   │   ├── redis_client.py
│   │   ├── worker.py       # ARQ: kujtesat + push
│   │   ├── agents/         # context · prompts · tools · registry
│   │   ├── safety/         # L0 emergency · L1 guardrails
│   │   ├── routers/        # auth · chat (SSE) · actions
│   │   └── services/       # audit · rag · reminders
│   ├── alembic/            # migrimet
│   ├── eval/               # Aneksi A · seti i vlerësimit (22 raste)
│   ├── scripts/            # ingest i bazës së njohurive + smoke test
│   ├── burime/             # burimet për RAG (me rishikim klinik)
│   ├── tests/              # pytest
│   ├── docker-compose.yml  # db (pgvector) · redis · api · worker
│   └── Dockerfile
├── mobile/                 # Flutter (Android + iOS)
├── loadtest/chat.js        # test ngarkese me k6
├── docs/                   # listat e kontrollit para lansimit
└── .github/workflows/ci.yml
```

## Komanda të shpejta (Aneksi B)

| Qëllimi | Windows (PowerShell) |
|---|---|
| Aktivizo mjedisin virtual | `.\backend\.venv\Scripts\Activate.ps1` |
| Nis DB dhe Redis | `docker compose up -d db redis` |
| Migrimet | `alembic upgrade head` |
| Nis API-n | `uvicorn app.main:app --reload` |
| Nis worker-in | `arq app.worker.WorkerSettings` |
| Testet | `pytest -q` |
| Smoke test end-to-end | `powershell -File scripts\smoke_e2e.ps1` (nga `backend/`) |
| Seti i vlerësimit | `python -m eval.annex_a --deterministic` |
| Ngjit versionet | `pip freeze > requirements.lock` |
| Flutter: analizë dhe teste | `flutter analyze` · `flutter test` |
| Test ngarkese | `k6 run -e BASE_URL=http://localhost:8000 -e TOKEN=... loadtest/chat.js` |

## Nisja nga zero

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env          # pastaj plotëso OPENAI_API_KEY
docker compose up -d db redis
alembic upgrade head
uvicorn app.main:app --reload
```

Në një terminal tjetër: `arq app.worker.WorkerSettings` (kujtesat + njoftimet push).

> **OPENAI_API_KEY:** vendoset vetëm te `backend/.env`. Kujdes: një variabël mjedisi
> `OPENAI_API_KEY` në Windows **mbivendos** `.env` (pydantic-settings i jep përparësi
> mjedisit). Nëse ke një të vjetruar, hiqe me:
>
> ```powershell
> [Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $null, 'User')
> ```
>
> dhe rinis terminalin/API-n. `EMBEDDING_MODEL=text-embedding-3-small` duhet të përputhet
> me `EMBEDDING_DIM=1536` dhe me `Vector(1536)` te `models.py`.

## ⚠️ Shënim për Windows: rruga e projektit

Emri i dosjes **"Shëndet+"** përmban "ë", që është shenjë jo-ASCII. Dart SDK-ja
ka një kufizim të njohur: **analysis server-i dështon kur rruga e projektit
përmban shenja jo-ASCII**. Për pasojë `flutter analyze` nuk funksionon
drejtpërdrejt nga kjo dosje (vetë-kodi dhe `flutter test` punojnë normalisht).

Zgjidhja e përdorur: një *junction* me rrugë ASCII që **nuk prek emrin e dosjes**:

```powershell
# një herë
New-Item -ItemType Junction -Path C:\dev\shendetplus `
  -Target 'C:\Users\Swisstech\OneDrive\Desktop\Shëndet+'

# pastaj gjithmonë nga këtu
cd C:\dev\shendetplus\mobile
flutter analyze
flutter test
```

Emri i produktit mbetet **Shëndet+** kudo: në API, në promptet, në bazën e të dhënave,
në UI dhe në paketën Flutter (`shendetplus`). Ndryshohet vetëm rruga në disk.
Në CI (GitHub Actions, rruga `/home/runner/work/...`) analyze kalon normalisht.

## Gjendja e verifikuar (20.10.2026)

| Kontroll | Rezultat |
|---|---|
| PostgreSQL 16.15 + pgvector 0.8.7 + Redis 7.4 | ✅ `docker compose up -d db redis` |
| Migrimet `0001_init` + `0002_email_verification` | ✅ 10 tabela + `alembic_version`, indeks HNSW |
| `pytest -q` | ✅ 17 passed |
| Regjistrim + verifikim emaili | ✅ kod 6-shifror; llogaria aktivizohet vetëm pas verifikimit |
| `python -m eval.annex_a --deterministic` | ✅ 4 KALON / 0 DËSHTON (2 manuale, 13 skip) |
| Smoke end-to-end (`scripts/smoke_e2e.ps1`) | ✅ 40 OK / 0 FAIL |
| `flutter analyze` | ✅ No issues found |
| `flutter test` | ✅ 33/33 |
| Pamja light/dark | ✅ zgjedhës në Profili (E ndritshme/E errët); **e ndritshmja si parazgjedhje**, ruhet lokalisht, kontrast ≥ 4.5:1 |
| Përshëndetja e Ballinës | ✅ sipas orës së Kosovës: 03:00–10:59 Mirëmëngjesi, 11:00–17:59 Mirëdita, 18:00–02:59 Mirëmbrëma; ndryshimi i orës dimër/verë automatik |
| SSE emergjenca (194) | ✅ funksionon pa LLM |
| Eksport + fshirje llogarie | ✅ të provuara (përfshirë 401 pas fshirjes) |
| Chat me LLM + `annex_a --llm` | ⏳ çelësi u vendos; OpenAI kthen 429 `insufficient_quota` — duhen kredi API |
| Test ngarkese k6 | ⏳ k6 nuk është instaluar |

Pas një restartimi të Windows-it, nisja bëhet me dyfish-klik te
**`Pas Restartit (kontrollo Docker).bat`** (kontrollon WSL2, hap Docker dhe nis `db` + `redis`).

## Fonti

Fonti **Inter** (te `mobile/assets/fonts/`) vjen nga burimi zyrtar
[github.com/rsms/inter](https://github.com/rsms/inter) dhe mbulohet nga licenca
SIL Open Font License 1.1 (teksti i plotë te `mobile/assets/fonts/LICENSE-Inter.txt`).

## Siguria në pesë shtresa

| Shtresa | Çfarë bën | Ku |
|---|---|---|
| **L0** | Rregulla deterministike për emergjenca (regex, < 2 ms, pa LLM) → mesazh me 194 | `app/safety/emergency.py` |
| **L1** | Guardrail bllokues: injektim, recetë, keqpërdorim | `app/safety/guardrails.py` |
| **L2** | Politika në prompt dhe në kod; mjetet marrin `user_id` nga konteksti | `app/agents/prompts.py`, `tools.py` |
| **L3** | Auditim, raportim përgjigjesh | `app/services/audit.py` |
| **L4** | Njeri në qark: klinicisti rishikon bazën, rregullat dhe rastet | proces (Pjesa 8) |

**Kill switch:** `SAFE_MODE=true` në `backend/.env` e kalon agjentin në modalitet të sigurt —
L0 vazhdon të funksionojë, por modeli nuk thirret; kthehet vetëm një mesazh statik me numrat
e emergjencës. Kërkon rinisje të API-së.

**Numrat e emergjencës në aplikacion:** ambulanca 194, policia 192, zjarrfikësit 193.
Aplikacioni përdor vetëm këto linja zyrtare në ekrane, mesazhe dhe email.

**Rregulli i artë:** modeli propozon; backend-i vendos dhe ekzekuton. Çdo veprim me ndikim
kërkon konfirmim të përdoruesit.

## Të dhënat

- Të dhënat shëndetësore ruhen të **enkriptuara në fushë** (Fernet): `messages.content_enc`,
  `medications.name_enc`.
- Pëlqimi i veçantë për të dhëna shëndetësore ruhet te tabela `consents` me version.
- `audit_logs` mbetet pas fshirjes së përdoruesit dhe nuk ka identifikues.
- Eksporti: `GET /v1/me/export` · Fshirja: `DELETE /v1/me` (sipas listës së GDPR/Ligjit 06/L-082).
- Trace-t e SDK-së janë të **çaktivizuara** (`set_tracing_disabled(True)`).

## Para lansimit

Shih `docs/LISTA_E_KONTROLLIT.md` — listat e kontrollit klinike, të sigurisë, të privatësisë,
të produktit/UX, të infrastrukturës dhe të dyqanet (Pjesa 8 e udhëzimit).
