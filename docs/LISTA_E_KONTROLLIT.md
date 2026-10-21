# Lista e kontrollit para lansimit (Pjesa 8 · udhëzuesi)

> Ky dokument është kopje besnike e listave të udhëzuesit. Çdo kuti duhet të shënohet
> nga përgjegjësi përpara se aplikacioni të publikohet me përdorues realë.

## Klinike

- [ ] Qëllimi i përdorimit i shkruar dhe i miratuar
- [ ] Set vlerësimit i kaluar (Aneksi A — `python -m eval.annex_a`)
- [ ] Lista L0 e rishikuar nga klinicisti
- [ ] 50 përgjigje të vlerësuara nga klinicisti
- [ ] Baza e njohurive e rishikuar, me burime dhe data
- [ ] Mesazhet e krizës dhe kontaktet lokale të verifikuara

## Siguri

- [ ] Pentest pa gjetje kritike
- [ ] Rate limit dhe kufij tokenash aktivë
- [ ] Red-team i injektimit dhe i keqpërdorimit
- [ ] Testet e izolimit mes përdoruesve
- [ ] Sekretet jashtë kodit dhe jashtë Git
- [ ] Kill switch për agjentin (modaliteti i sigurt)

## Privatësi

- [ ] DPIA e përfunduar
- [ ] DPA me çdo ofrues (LLM, cloud, Firebase)
- [ ] Pëlqim i veçantë për të dhëna shëndetësore
- [ ] Trace dhe logs pa përmbajtje bisedash
- [ ] Eksport dhe fshirje të dhënash të provuara
- [ ] Politika e privatësisë me URL publike

## Produkt dhe UX

- [ ] Aksesueshmëria AA e testuar
- [ ] Teksti i dyqanit pa premtime mjekësore
- [ ] Gjendjet bosh/gabim/offline të dizajnuara
- [ ] Mekanizëm raportimi i përgjigjeve (chip-i "Raporto")
- [ ] Butoni i emergjencës në çdo ekran
- [x] Numrat e emergjencës: ambulanca 194, policia 192, zjarrfikësit 193; vetëm këto shfaqen

## Infrastrukturë

- [ ] Backup dhe rikthim i provuar
- [ ] Migrimet e automatizuara
- [ ] Alarme dhe paneli aktiv
- [ ] Plan i incidenteve i provuar
- [ ] Test ngarkese i kaluar (`k6 run loadtest/chat.js`)
- [ ] Rajon dhe rezidencë të dhënash të konfirmuara (BE)

## Dyqanet

- [ ] Deklaratat e privatësisë/shëndetit të plotësuara (App Store + Play Console)
- [ ] Llogari testimi për rishikuesit
- [ ] Fshirja e llogarisë brenda aplikacionit
- [ ] Lansim gradual (10%, 25%, 50%, 100%)
- [ ] Screenshots dhe përshkrim të rishikuar

---

## Statusi teknik i verifikimit (19.10.2026)

Këto janë kontrolle teknike në mjedisin e zhvillimit. **Nuk zëvendësojnë** nënshkrimet
njerëzore (klinike, ligjore, DPO) që kërkon lista e mësipërme.

| Kontrolli | Statusi | Dëshmia |
|---|---|---|
| Aneksi A — pjesa deterministike | ✅ 4 KALON / 0 DËSHTON | `python -m eval.annex_a --deterministic` |
| Aneksi A — me LLM | ⏳ çelësi u vendos; pret kredi API (429 `insufficient_quota`) | `python -m eval.annex_a --llm` |
| Rate limit 20/min | ✅ 20 OK / 5 × 429 | test i veçantë |
| Izolimi mes përdoruesve | ✅ 404 për bisedë të huaj | `smoke_e2e.ps1` hapi 6 |
| Eksport + fshirje llogarie | ✅ përfshirë 401 pas fshirjes | `smoke_e2e.ps1` hapi 7 |
| SSE emergjenca (194) | ✅ pa LLM; vetëm linjat zyrtare | `smoke_e2e.ps1` hapi 3 |
| Numrat në UI dhe API | ✅ ambulanca 194, policia 192, zjarrfikësit 193 | `emergency_page.dart`, `emergency.py` |
| Regjistrim + verifikim emaili | ✅ llogaria aktivizohet vetëm pas kodit 6-shifror | `smoke_e2e.ps1` hapi 2 + browser E2E |
| Kill switch (`SAFE_MODE=true`) | ✅ vetëm L0 + mesazh statik | instancë testuese në portën 8001 |
| Migrimet + `vector` + HNSW | ✅ `0001_init` + `0002_email_verification` | `alembic upgrade head` |
| Build i imazhit Docker | ⏳ në progres | `docker compose build api` |
| Test ngarkese k6 | ⏳ k6 mungon | `loadtest/chat.js` |
| `pytest -q` | ✅ 17 passed | |
| `flutter analyze` | ✅ No issues found | |
| `flutter test` | ✅ 33/33 | |
| Pamja light/dark | ✅ zgjedhësi te Profili; e ndritshmja si parazgjedhje, ruhet pas rihapjes | `theme_test.dart` · `theme_mode.dart` |
| Përshëndetja e Ballinës | ✅ sipas orës së Kosovës (03–11, 11–18, 18–03), me DST automatik | `greeting_test.dart` · `kosovo_time.dart` |

### Si t'i provosh vetë

```powershell
cd backend
powershell -File scripts\smoke_e2e.ps1
```

## Plani i incidenteve (Pjesa 8.4)

| Hapi | Veprimi | Përgjegjësi |
|---|---|---|
| 1 · Zbulo | Alarm automatik, raport përdoruesi ose rishikim i mostrës | Të gjithë |
| 2 · Ndërpre | Aktivizo kill switch: aplikacioni kalon në modalitet të sigurt (L0 + mesazh statik) | DevOps |
| 3 · Vlerëso | Klinicisti dhe backend-i përcaktojnë shkakun dhe sa përdorues preken | Klinicisti + backend |
| 4 · Njofto | Përdoruesit dhe autoriteti sipas ligjit; për shkelje të të dhënave, GDPR kërkon njoftim brenda 72 orëve kur ka rrezik | DPO |
| 5 · Korrigjo | Rregullo, shto test regresioni, rikthe gradualisht | Backend |
| 6 · Mëso | Analizë pa fajësim brenda 5 ditëve; përditëso setin e vlerësimit | Të gjithë |

## Ekipi minimal (Pjesa 8.2)

| Roli | Përgjegjësia | Shënim |
|---|---|---|
| Pronari i produktit | Prioritete, metrika, qëllimi i përdorimit | — |
| Këshilltar klinik | Rregullat L0, politika e përgjigjeve, baza e njohurive, rishikim javor | **I detyrueshëm**, edhe me kohë të pjesshme |
| Inxhinier backend/AI | API, agjentët, RAG, siguria teknike | — |
| Inxhinier mobil | Flutter, aksesueshmëria, njoftimet | — |
| Dizajner UX/UI | Sistemi i dizajnit, ekranet, teste përdorshmërie | — |
| QA | Teste, set vlerësimi, regresion sigurie | — |
| Jurist/DPO dhe DevOps | Privatësia, kontratat, infrastruktura dhe sekretet | Mund të jenë jashtë ekipit |

> **KUJDES — Nëse punon vetëm:** mund ta ndërtosh prototipin vetë, por këshilltari klinik
> dhe rishikimi ligjor nuk anashkalohen para përdoruesve realë. Fillo me një beta të vogël
> dhe të mbyllur.
