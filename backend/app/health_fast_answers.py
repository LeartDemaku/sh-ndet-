"""Përgjigje të shpejta dhe të sigurta për pyetjet më të zakonshme shëndetësore.

Këto përgjigje nuk zëvendësojnë mjekun. Ato përdoren vetëm për informacion të
përgjithshëm dhe për të shmangur pritjen e gjatë të modelit kur pyetja është e
qartë. Pyetjet me simptoma urgjente kapen më parë nga check_emergency().
"""

from __future__ import annotations

import re

from app.safety.emergency import emergency_number, normalize


_FLU_VACCINE = re.compile(
    r"\bvaksin\w*\b.*\b(grip\w*|influenza\w*|sezonal\w*)\b"
    r"|\b(grip\w*|influenza\w*|sezonal\w*)\b.*\bvaksin\w*\b"
)
_FEVER = re.compile(r"\b(ethe|temperatur\w*|temperature)\b")
_FLU = re.compile(r"\b(grip\w*|influenza\w*|ftohj\w*|ftoht\w*)\b")
_HEADACHE = re.compile(r"\b(dhimbje koke|migren\w*|koke)\b")
_DIABETES = re.compile(r"\b(diabet\w*|sheqer\w* ne gjak|glukoz\w*)\b")


def _text(text: str) -> str:
    return normalize(text)


def fast_health_answer(text: str) -> str | None:
    """Kthen një përgjigje të menjëhershme ose None nëse duhet modeli."""
    norm = _text(text)

    if _FLU_VACCINE.search(norm):
        return (
            "Vaksina kundër gripit sezonal rekomandohet zakonisht çdo vjeshtë, "
            "sidomos për personat mbi 65 vjeç, shtatzënat, fëmijët e vegjël, "
            "personat me sëmundje kronike dhe punonjësit shëndetësorë. "
            "Nëse nuk ke pasur reaksion të rëndë ndaj vaksinës ose nuk ke "
            "kundërindikacion të njohur, mund të vaksinohesh; nëse ke ethe ose "
            "infeksion aktiv, shtyje derisa të jesh më mirë. "
            "Në Kosovë, kontrollo qendrën e mjekësisë familjare për "
            "disponueshmërinë aktuale të vaksinës. Vendimin përfundimtar e jep "
            "mjeku ose farmacisti."
        )

    if _FEVER.search(norm):
        return (
            "Nëse ke ethe, pusho, pij lëngje dhe mat temperaturën. Mund të "
            "përdorësh paracetamol sipas udhëzimit të paketimit ose të "
            "farmacistit, por mos e kombino me ilaçe të tjera që e përmbajnë. "
            "Kërko ndihmë mjekësore nëse temperatura është shumë e lartë, zgjat "
            "më shumë se 3 ditë, ose ke vështirësi në frymëmarrje, ngurtësi të "
            "qafës, skuqje, konfuzion, ose je shtatzënë/fëmijë i vogël."
        )

    if _FLU.search(norm):
        return (
            "Gripi dhe ftohja zakonisht përmirësohen me pushim, lëngje dhe kohë. "
            "Nëse ke ethe, dhimbje trupi ose kollë, ndiq simptomat dhe mos merr "
            "antibiotikë pa mjekun. Kontakto mjekun nëse ke vështirësi në "
            "frymëmarrje, dhimbje gjoksi, konfuzion, ethe të larta që nuk ulen, "
            "ose simptomat zgjasin më shumë se 7–10 ditë."
        )

    if _HEADACHE.search(norm):
        return (
            "Pusho, pij ujë dhe shmang dritën e fortë. Shumica e dhimbjeve të "
            "kokës përmirësohen vetë, por kërko ndihmë menjëherë nëse dhimbja "
            "fillon papritur dhe është shumë e fortë, ose shoqërohet me dobësi, "
            "mpirje, vështirësi në të folur, vështirësi në shikim, ethe ose "
            "ngurtësi të qafës, ose pas një goditjeje në kokë."
        )

    if _DIABETES.search(norm):
        return (
            "Diabeti është gjendje ku sheqeri në gjak mbetet i lartë për shkak "
            "të mungesës ose funksionimit të dobët të insulinës. Simptomat e "
            "zakonshme përfshijnë etje, urinim të shpeshtë, lodhje dhe humbje "
            "peshe, por diagnoza bëhet me analiza. Nëse dyshon, kontakto mjekun; "
            "nëse ke konfuzion, vështirësi në frymëmarrje, të vjella të "
            "përsëritura ose sheqer shumë të lartë, kërko ndihmë urgjente."
        )

    return None


def offline_answer(text: str, country: str = "XK") -> str:
    """Përgjigje e sigurt kur modeli nuk përgjigjet ose është i zënë."""
    local = fast_health_answer(text)
    if local:
        return local
    return (
        "Nuk arrita të marr përgjigje nga shërbimi i AI tani. Për të mos dhënë "
        "informacion të pasigurt, nuk po hamendësoj. Provo përsëri pas pak ose "
        "konsulto mjekun/farmacistin. "
        f"Nëse është urgjente, telefono {emergency_number(country)}."
    )
