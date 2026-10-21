from app.services.email_verification import (
    codes_match,
    generate_code,
    hash_code,
    is_test_email,
    mask_email,
    render_verification_email,
)


def test_generate_code_is_six_digits():
    codes = {generate_code() for _ in range(100)}
    assert all(len(c) == 6 and c.isdigit() for c in codes)
    assert len(codes) > 95  # praktikisht pa përsëritje


def test_hash_code_never_stores_plain_code():
    code = "123456"
    hashed = hash_code(code, "pepper-i-testit")
    assert hashed != code
    assert len(hashed) == 64
    assert all(ch in "0123456789abcdef" for ch in hashed)


def test_hash_code_is_deterministic_and_pepper_sensitive():
    assert hash_code("654321", "pepper-a") == hash_code("654321", "pepper-a")
    assert hash_code("654321", "pepper-a") != hash_code("654321", "pepper-b")
    assert hash_code("654321", "pepper-a") != hash_code("654322", "pepper-a")


def test_codes_match_uses_same_hash():
    code = "246810"
    hashed = hash_code(code, "pepper")
    assert codes_match(code, hashed, "pepper")
    assert not codes_match("246811", hashed, "pepper")


def test_test_email_domains_are_recognized():
    assert is_test_email("test@example.com")
    assert is_test_email("test@example.org")
    assert not is_test_email("leart.demaku2006@gmail.com")


def test_mask_email_does_not_expose_full_local_part():
    assert mask_email("leart.demaku2006@gmail.com") == "le***@gmail.com"
    assert "leart" not in mask_email("leart.demaku2006@gmail.com")


def test_render_email_contains_code_and_ttl():
    text, html = render_verification_email("987654", 10)
    assert "987654" in text
    assert "987654" in html
    assert "10" in text
    assert "Shëndet+" in text
    assert "194" in text
    assert "112" not in text
    assert "Kodi i verifikimit" in html
