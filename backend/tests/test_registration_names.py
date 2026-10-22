from pydantic import ValidationError
import pytest

from app.routers.auth import RegisterIn
from app.services.display_name import first_name_from_email


def _payload(**overrides):
    data = {
        "first_name": "Leart",
        "last_name": "Demaku",
        "email": "leart@example.com",
        "password": "TestFjalekalim123!",
        "country": "XK",
        "accept_terms": True,
        "accept_health_data": True,
    }
    data.update(overrides)
    return data


def test_register_requires_first_and_last_name():
    with pytest.raises(ValidationError):
        RegisterIn(**_payload(first_name=""))
    with pytest.raises(ValidationError):
        RegisterIn(**_payload(last_name=""))


def test_register_trims_names():
    data = RegisterIn(**_payload(first_name="  Leart  ", last_name=" Demaku "))
    assert data.first_name == "Leart"
    assert data.last_name == "Demaku"


def test_legacy_account_gets_first_name_from_own_email():
    assert first_name_from_email("leart.demaku2006@gmail.com") == "Leart"
    assert first_name_from_email("ana_krasniqi+test@example.com") == "Ana"
    assert first_name_from_email("x@example.com") is None
