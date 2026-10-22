import re


def first_name_from_email(email: str) -> str | None:
    """Nxjerr një emër të parë vetëm për llogaritë e vjetra pa emër.

    Llogaritë e reja e kanë emrin e regjistrimit. Kjo funksion vetëm sa për
    të mos i lënë llogaritë e vjetra me përshëndetje të përgjithshme. Nuk
    ruhet në bazë dhe email-i nuk shfaqet askund.
    """
    local = email.strip().split("@", 1)[0]
    for part in re.split(r"[._\-+\d]+", local):
        cleaned = "".join(ch for ch in part if ch.isalpha())
        if len(cleaned) >= 2:
            return cleaned[:1].upper() + cleaned[1:].lower()
    return None
