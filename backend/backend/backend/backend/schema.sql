
-- =========================================
-- MIFADO COIN - PRODUCTION DATABASE SCHEMA
-- =========================================

BEGIN;

-- 1. USERS
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    telegram_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(64),
    first_name VARCHAR(128),
    language VARCHAR(5) DEFAULT 'en',
    balance NUMERIC(30,8) NOT NULL DEFAULT 0,
    energy INTEGER NOT NULL DEFAULT 1000,
    max_energy INTEGER NOT NULL DEFAULT 1000,
    hourly_rate NUMERIC(20,8) NOT NULL DEFAULT 1,
    last_mining_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_users_telegram
ON users(telegram_id);

-- 2. TRANSACTIONS
CREATE TABLE IF NOT EXISTS transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    type VARCHAR(32) NOT NULL,
    amount NUMERIC(30,8) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'completed',
    reference VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(128);

ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_idempotency
ON transactions(idempotency_key)
WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
ON transactions(user_id, created_at DESC);

-- 3. MINING UPGRADE CATALOG
CREATE TABLE IF NOT EXISTS upgrade_catalog (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(128) NOT NULL,
    level INTEGER NOT NULL,
    price NUMERIC(30,8) NOT NULL,
    hourly_bonus NUMERIC(20,8) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(code, level),
    CHECK (price >= 0),
    CHECK (hourly_bonus >= 0)
);

-- 4. USER PURCHASED UPGRADES
CREATE TABLE IF NOT EXISTS user_upgrades (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    upgrade_id BIGINT NOT NULL REFERENCES upgrade_catalog(id),
    purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, upgrade_id)
);

CREATE INDEX IF NOT EXISTS idx_user_upgrades_user
ON user_upgrades(user_id);

-- 5. REFERRALS
CREATE TABLE IF NOT EXISTS referrals (
    id BIGSERIAL PRIMARY KEY,
    referrer_id BIGINT NOT NULL REFERENCES users(id),
    referred_id BIGINT NOT NULL UNIQUE REFERENCES users(id),
    reward_amount NUMERIC(30,8) NOT NULL DEFAULT 0,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (referrer_id <> referred_id)
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer
ON referrals(referrer_id);

-- 6. TASK CATALOG
CREATE TABLE IF NOT EXISTS tasks (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(160) NOT NULL,
    description TEXT,
    reward NUMERIC(30,8) NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (reward >= 0)
);

-- 7. USER TASK COMPLETIONS
CREATE TABLE IF NOT EXISTS user_tasks (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    task_id BIGINT NOT NULL REFERENCES tasks(id),
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, task_id)
);

-- 8. WITHDRAWAL REQUESTS
CREATE TABLE IF NOT EXISTS withdrawals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    amount NUMERIC(30,8) NOT NULL,
    wallet_address VARCHAR(128) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    ton_tx_hash VARCHAR(128),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user
ON withdrawals(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_withdrawals_status
ON withdrawals(status);

-- 9. STARTER UPGRADE LEVELS
INSERT INTO upgrade_catalog
(code, title, level, price, hourly_bonus)
VALUES
('miner', 'Basic Miner', 1, 100, 1),
('miner', 'Advanced Miner', 2, 250, 2),
('miner', 'Pro Miner', 3, 600, 4),
('miner', 'Elite Miner', 4, 1500, 8),
('miner', 'Ultra Miner', 5, 3500, 15)
ON CONFLICT (code, level) DO NOTHING;

COMMIT;
