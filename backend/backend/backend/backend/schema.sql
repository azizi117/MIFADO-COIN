
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    telegram_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(64),
    first_name VARCHAR(128),
    language VARCHAR(5) DEFAULT 'en',
    balance NUMERIC(30, 8) DEFAULT 0,
    energy INTEGER DEFAULT 1000,
    max_energy INTEGER DEFAULT 1000,
    hourly_rate NUMERIC(20, 8) DEFAULT 0,
    last_mining_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    type VARCHAR(32) NOT NULL,
    amount NUMERIC(30, 8) NOT NULL,
    status VARCHAR(24) DEFAULT 'completed',
    reference VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS upgrades (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(128) NOT NULL,
    price NUMERIC(30, 8) NOT NULL,
    hourly_bonus NUMERIC(20, 8) DEFAULT 0,
    level INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_transactions_user
ON transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_created
ON transactions(created_at);
