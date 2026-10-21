import re
import unicodedata
from dataclasses import dataclass
from typing import Literal

Level = Literal["emergency", "crisis"]


@dataclass(frozen=True)
class EmergencyResult:
    level: Level
    category: str
    matched: str


def normalize(text: str) -> str:
    """Shkronja të vogla, pa diakritikë (ë->e, ç->c), pa pikësim."""
    t = unicodedata.normalize("NFKD", text.lower())
    t = "".join(ch for ch in t if not unicodedata.combining(ch))
    t = t.replace("'", "").replace("\u2019", "")
    t = re.sub(r"[^a-z0-9\s]", " ", t)
    return re.sub(r"\s+", " ", t).strip()


W = r"(?:\w+\s+){0,3}"   # deri në 3 fjalë ndërmjet

RULES: dict[tuple[Level, str], list[str]] = {
    ("crisis", "vetedemtim"): [
        r"dua te vdes", r"dua te vras veten", r"vras veten", r"vetevrasj",
        r"(lendoj|demtoj) veten", r"\bs?nuk dua te jetoj", r"\bsdua te jetoj",
        r"kill myself", r"want to die", r"suicid", r"end my life", r"hurt myself",
    ],
    ("emergency", "gjoks"): [
        rf"dhimbj\w*\s+{W}gjoks", rf"shtypje\s+{W}gjoks", r"infarkt",
        r"chest (pain|pressure|tightness)", r"heart attack",
    ],
    ("emergency", "frymemarrje"): [
        r"nuk (mund te )?m[ae]rr fryme", rf"veshtiresi\w*\s+{W}frymemarrj",
        r"me merret fryma", r"me mbytet fryma", r"po mbytem",
        r"(cant|cannot|can not) breathe", r"difficulty breathing",
    ],
    ("emergency", "vetedije"): [
        rf"humb\w*\s+{W}(ndjenj|ndergjegj|vetedij)", r"nuk (zgjohet|reagon)",
        r"unconscious", r"unresponsive", r"passed out",
    ],
    ("emergency", "goditje"): [
        r"nuk mund te flas", r"belbez", rf"(dobesi|mpirje)\s+{W}(ane|krah|kembe|fytyr)",
        rf"goditj\w*\s+{W}tru", r"\bstroke\b", r"face drooping",
    ],
    ("emergency", "gjakderdhje"): [
        rf"gjakderdhj\w*\s+{W}(forte|madhe|masive|pandalshme)",
        r"nuk ndalet gjaku", r"gjaku nuk ndalet", r"severe bleeding",
        r"(wont|will not) stop bleeding",
    ],
    ("emergency", "alergji"): [
        rf"reaksion\s+alergjik\s+{W}(rende|forte|rrezikshem)",
        rf"fryhet\s+{W}(fyti|gjuha|buzet|fytyra)", r"anaphyla",
    ],
    ("emergency", "kriza"): [
        rf"kriz\w*\s+{W}epilept", r"konvulsion", r"\bseizure\b",
    ],
    ("emergency", "helmim"): [
        r"mbidoz", r"overdose", r"helmim", r"\bpoisoned?\b",
        rf"(mora|piva|gelltita)\s+{W}shume\s+(tableta|ilace|pilula)",
    ],
}

_COMPILED = {key: [re.compile(p) for p in pats] for key, pats in RULES.items()}
_NEGATION = re.compile(r"(?:^|\s)(?:nuk|pa|no|not|without|never)(?:\s+(?:kam|ka|ndiej|have|has|any))*$")

NUMBERS = {
    # Kosovë: ambulanca 194, policia 192, zjarrfikësit 193.
    "XK": {"emergency": "194"},
    "US": {"emergency": "911"},
    "DEFAULT": {"emergency": "194"},
}


def check_emergency(text: str) -> EmergencyResult | None:
    norm = normalize(text)
    for (level, category), patterns in _COMPILED.items():
        for pat in patterns:
            m = pat.search(norm)
            if not m:
                continue
            prefix = norm[: m.start()].rstrip()
            if level == "emergency" and _NEGATION.search(prefix):
                continue          # p.sh. "nuk kam dhimbje në gjoks"
            return EmergencyResult(level, category, m.group(0))
    return None


def emergency_number(country: str) -> str:
    return NUMBERS.get(country, NUMBERS["DEFAULT"])["emergency"]


def emergency_message(res: EmergencyResult, country: str = "XK") -> str:
    n = NUMBERS.get(country, NUMBERS["DEFAULT"])
    if res.level == "crisis":
        return (
            "Më vjen keq që po e kalon këtë. Nuk je vetëm dhe ndihma ekziston.\n"
            f"Nëse je në rrezik të menjëhershëm, telefono tani {n['emergency']}.\n"
            "Nëse mundesh, flit me një person të afërt ose të besuar që është me ty."
        )
    return (
        "Simptomat që përshkruan mund të jenë urgjente.\n"
        f"Telefono menjëherë {n['emergency']} ose shko në urgjencën më të afërt.\n"
        "Mos prit përgjigje nga aplikacioni. Nëse je me dikë, kërko ndihmën e "
        "personit që është me ty."
    )
