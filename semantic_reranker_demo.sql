\i semantic_reranker.sql

DROP TABLE IF EXISTS cnn_daily_20241119;

CREATE TABLE cnn_daily_20241119(id text primary key, article text, highlights text);
\copy cnn_daily_20241119 FROM 'cnn_daily.csv' WITH (FORMAT csv, HEADER true);

ALTER TABLE cnn_daily_20241119 ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Generate embeddings -- this may take a while
DO $$ 
DECLARE
    tmprow record;
BEGIN
    FOR tmprow IN SELECT id, article FROM cnn_daily_20241119 LOOP
        UPDATE cnn_daily_20241119 SET embedding = azure_openai.create_embeddings('text-embedding-3-small', tmprow.article, throw_on_error => FALSE, max_attempts => 1000, retry_delay_ms => 2000)  WHERE id = tmprow.id;
    END LOOP;
END $$;

-- Create HNSW index --
CREATE INDEX ON cnn_daily_20241119 USING hnsw (embedding vector_cosine_ops);

-- Retrieve 10 articles similar to the query, rerank them, and return the top 3 --
WITH 
retrieval_result AS(
    SELECT
        c.article as articles
    FROM
        cnn_daily_20241119 c
    ORDER BY
        c.embedding <=> azure_openai.create_embeddings('text-embedding-3-small', 'Latest news on artificial intelligence', throw_on_error => FALSE, max_attempts => 1000, retry_delay_ms => 2000)::vector
    LIMIT 10
)
select article, relevance from semantic_reranking('Latest news on artificial intelligence', array (select articles from retrieval_result)) order by relevance DESC limit 3;