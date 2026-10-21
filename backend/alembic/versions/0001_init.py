"""alembic/versions/0001_init.py

Migrimi fillestar i Shëndet+.

Sipas udhëzimit, dy pjesët e mëposhtme shtohen ME DORË (nuk i jep autogenerate):
  1. CREATE EXTENSION IF NOT EXISTS vector  -- PARA krijimit të tabelave
  2. indeksi HNSW mbi knowledge_chunks.embedding

Pa pjesën e parë, kolona `embedding vector(1536)` nuk njihet nga PostgreSQL.
Pa `import pgvector.sqlalchemy`, autogenerate-ja jep: NameError: 'pgvector'.
"""
import pgvector.sqlalchemy  # noqa: F401  pa këtë: NameError gjatë autogenerate
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision = "0001_init"
down_revision = None
branch_labels = None
depends_on = None

EMBED_DIM = 1536  # duhet të përputhet me EMBEDDING_DIM te .env
TS = sa.DateTime(timezone=True)


def upgrade() -> None:
    # 1) Shtesa e dorës nga udhëzimi: ekstensioni pgvector PARA tabelave.
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(320), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("country", sa.String(2), nullable=False),
        sa.Column("locale", sa.String(5), nullable=False),
        sa.Column("tz", sa.String(40), nullable=False),
        sa.Column("created_at", TS, server_default=sa.text("now()"), nullable=False),
        sa.Column("deleted_at", TS, nullable=True),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "consents",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("version", sa.String(16), nullable=False),
        sa.Column("granted_at", TS, server_default=sa.text("now()"), nullable=False),
        sa.Column("revoked_at", TS, nullable=True),
    )
    op.create_index("ix_consents_user_id", "consents", ["user_id"])

    op.create_table(
        "conversations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", TS, server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_conversations_user_id", "conversations", ["user_id"])

    op.create_table(
        "messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("conversation_id", UUID(as_uuid=True),
                  sa.ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(12), nullable=False),
        sa.Column("content_enc", sa.Text, nullable=False),  # tekst i enkriptuar
        sa.Column("safety_level", sa.String(16), nullable=True),
        sa.Column("triage_level", sa.String(24), nullable=True),
        sa.Column("created_at", TS, server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_messages_conversation_id", "messages", ["conversation_id"])
    op.create_index("ix_messages_created_at", "messages", ["created_at"])

    op.create_table(
        "medications",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name_enc", sa.Text, nullable=False),  # emri i enkriptuar
        sa.Column("active", sa.Boolean, nullable=False),
        sa.Column("created_at", TS, server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_medications_user_id", "medications", ["user_id"])

    op.create_table(
        "reminders",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("medication_id", UUID(as_uuid=True),
                  sa.ForeignKey("medications.id", ondelete="CASCADE"), nullable=False),
        sa.Column("at_time", sa.Time, nullable=False),
        sa.Column("tz", sa.String(40), nullable=False),
        sa.Column("next_fire_at", TS, nullable=False),
        sa.Column("active", sa.Boolean, nullable=False),
    )
    op.create_index("ix_reminders_user_id", "reminders", ["user_id"])
    op.create_index("ix_reminders_medication_id", "reminders", ["medication_id"])
    op.create_index("ix_reminders_next_fire_at", "reminders", ["next_fire_at"])

    op.create_table(
        "devices",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("fcm_token", sa.String(255), nullable=False, unique=True),
        sa.Column("platform", sa.String(10), nullable=False),
    )
    op.create_index("ix_devices_user_id", "devices", ["user_id"])

    op.create_table(
        "knowledge_chunks",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("source", sa.String(120), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("url", sa.String(500), nullable=False),
        sa.Column("lang", sa.String(5), nullable=False),
        sa.Column("text", sa.Text, nullable=False),
        sa.Column("embedding", pgvector.sqlalchemy.Vector(EMBED_DIM), nullable=False),
        # Vetëm copëzat e rishikuara klinikisht kthehen te agjenti.
        sa.Column("reviewed_by", sa.String(80), nullable=True),
        sa.Column("reviewed_at", TS, nullable=True),
    )
    op.create_index("ix_knowledge_chunks_lang", "knowledge_chunks", ["lang"])

    # 2) Shtesa e dorës nga udhëzimi: indeksi HNSW për kërkimin vektorial.
    op.execute(
        "CREATE INDEX IF NOT EXISTS knowledge_chunks_embedding_hnsw "
        "ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)"
    )

    # Tabela e auditit: PA FK me qëllim, që log-u të mbetet edhe pas fshirjes
    # së përdoruesit (dhe pa identifikues pas fshirjes GDPR).
    op.create_table(
        "audit_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True), nullable=True),
        sa.Column("action", sa.String(48), nullable=False),
        sa.Column("resource", sa.String(80), nullable=False),
        sa.Column("meta", JSONB, nullable=False),
        sa.Column("created_at", TS, server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_audit_logs_user_id", "audit_logs", ["user_id"])
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS knowledge_chunks_embedding_hnsw")
    for table in (
        "audit_logs", "knowledge_chunks", "devices", "reminders",
        "medications", "messages", "conversations", "consents", "users",
    ):
        op.drop_table(table)
