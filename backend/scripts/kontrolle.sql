-- backend/scripts/kontrolle.sql
-- Kontrolle të shpejta pas migrimit (nga udhëzimi).
-- Ekzekuto: docker compose exec db psql -U shendet -d shendetplus -f /dev/stdin < scripts/kontrolle.sql

-- 1) A është instaluar ekstensioni pgvector?
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';

-- 2) Sa copëza burimore janë të rishikuara klinikisht?
--    VETËM ato me reviewed_at NOT NULL kthehen te agjenti.
SELECT lang,
       count(*) FILTER (WHERE reviewed_at IS NOT NULL) AS reviewed,
       count(*)                                        AS total
FROM knowledge_chunks
GROUP BY lang;

-- 3) Kujtesat që duhen dërguar tani (pa dyfishim me worker-in).
SELECT id, user_id, next_fire_at
FROM reminders
WHERE active AND next_fire_at <= now()
ORDER BY next_fire_at
LIMIT 20;

-- 4) Tabelat e krijuara.
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 5) Indeksi HNSW ekziston?
SELECT indexname FROM pg_indexes
WHERE indexname = 'knowledge_chunks_embedding_hnsw';

-- 6) Verifikim i enkriptimit në fushë: asnjë tekst i qartë te messages.
--    Kolona quhet content_enc: vlera duhet të fillojë me "gAAAAA" (Fernet).
SELECT left(content_enc, 6) AS prefiksi, count(*)
FROM messages
GROUP BY 1;
