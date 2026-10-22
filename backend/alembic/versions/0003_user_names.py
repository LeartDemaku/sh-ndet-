"""Emri dhe mbiemri i përdoruesit për përshëndetjen e personalizuar.

Kolonat janë nullable që llogaritë ekzistuese të mbeten të vlefshme; ato
shfaqin përshëndetjen e përgjithshme derisa përdoruesi t'i plotësojë.
"""

import sqlalchemy as sa
from alembic import op

revision = "0003_user_names"
down_revision = "0002_email_verification"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("first_name", sa.String(80), nullable=True))
    op.add_column("users", sa.Column("last_name", sa.String(80), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "last_name")
    op.drop_column("users", "first_name")
