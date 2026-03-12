-- =====================================
-- Core URL Storage Table
-- =====================================
CREATE TABLE IF NOT EXISTS urls (
    id           SERIAL PRIMARY KEY,
    short_code   VARCHAR(20) UNIQUE NOT NULL,
    long_url     TEXT NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at   TIMESTAMP,
    click_count  INTEGER DEFAULT 0,
    password_hash VARCHAR(255),
    webhook_url  TEXT,
    is_custom    BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_urls_short_code ON urls(short_code);
CREATE INDEX IF NOT EXISTS idx_urls_expires_at ON urls(expires_at);

-- =====================================
-- Analytics / Clickstream Table
-- =====================================
CREATE TABLE IF NOT EXISTS analytics (
    id          SERIAL PRIMARY KEY,
    short_code  VARCHAR(20) NOT NULL,
    clicked_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address  VARCHAR(45),
    user_agent  TEXT,
    country     VARCHAR(2),
    city        VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_analytics_short_code ON analytics(short_code);
CREATE INDEX IF NOT EXISTS idx_analytics_clicked_at ON analytics(clicked_at);

-- =====================================
-- URL Metadata (Preview / OG Tags)
-- =====================================
CREATE TABLE IF NOT EXISTS url_meta (
    short_code  VARCHAR(20) PRIMARY KEY,
    title       TEXT,
    description TEXT,
    og_image    TEXT,
    fetched_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (short_code) REFERENCES urls(short_code) ON DELETE CASCADE
);
