from pydantic import ValidationError
import pytest

from app.routers.auth import RegisterIn


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
