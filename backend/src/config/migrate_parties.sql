-- Migration: add parties table and party_id FK to transactions
-- Run once against the live database

CREATE TABLE IF NOT EXISTS parties (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  type VARCHAR(10) NOT NULL DEFAULT 'customer' CHECK (type IN ('customer','vendor')),
  opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS party_id INTEGER REFERENCES parties(id) ON DELETE SET NULL;

GRANT ALL PRIVILEGES ON TABLE parties TO officeflow;
GRANT ALL PRIVILEGES ON SEQUENCE parties_id_seq TO officeflow;
