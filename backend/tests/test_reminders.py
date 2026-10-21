from datetime import datetime, time, timezone

from app.services.reminders import next_fire


def test_next_fire_uses_local_timezone_in_winter():
    after = datetime(2026, 1, 10, 12, 0, tzinfo=timezone.utc)
    assert next_fire(time(8, 0), "Europe/Belgrade", after) == datetime(
        2026, 1, 11, 7, 0, tzinfo=timezone.utc
    )


def test_next_fire_respects_summer_time():
    after = datetime(2026, 7, 10, 5, 0, tzinfo=timezone.utc)
    assert next_fire(time(8, 0), "Europe/Belgrade", after) == datetime(
        2026, 7, 10, 6, 0, tzinfo=timezone.utc
    )
