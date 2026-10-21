"""Verifikimi i emailit gjatë regjistrimit (faktor i dytë).

- Shton `users.email_verified_at`.
- Krijon `email_verifications` (vetëm hash-i HMAC i kodit).
- Përdoruesit ekzistues shënohen të verifikuar, që të mos mbyllen jashtë.
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision = "0002_email_verification"
down_revision = "0001_init"
branch_labels = None
depends_on = None

TS = sa.DateTime(timezone=True)


def upgrade() -> None:
    op.add_column("users", sa.Column("email_verified_at", TS, nullable=True))

    op.create_table(
        "email_verifications",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("code_hash", sa.String(64), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("expires_at", TS, nullable=False),
        sa.Column("consumed_at", TS, nullable=True),
        sa.Column("created_at", TS, nullable=False, server_default=sa.text("now()")),
    )
    op.create_index(
        "ix_email_verifications_user_id", "email_verifications", ["user_id"]
    )
    op.create_index(
        "ix_email_verifications_expires_at", "email_verifications", ["expires_at"]
    )
    op.create_index(
        "ix_email_verifications_created_at", "email_verifications", ["created_at"]
    )

    # Llogaritë ekzistuese nuk duhet të bllokohen nga kërkesa e re.
    op.execute(
        "UPDATE users SET email_verified_at = created_at "
        "WHERE email_verified_at IS NULL"
    )


def downgrade() -> None:
    op.drop_index("ix_email_verifications_created_at", table_name="email_verifications")
    op.drop_index("ix_email_verifications_expires_at", table_name="email_verifications")
    op.drop_index("ix_email_verifications_user_id", table_name="email_verifications")
    op.drop_table("email_verifications")
    op.drop_column("users", "email_verified_at")
