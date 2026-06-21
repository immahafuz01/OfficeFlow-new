-- OfficeFlow Database Schema

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role VARCHAR(20) DEFAULT 'viewer' CHECK (role IN ('admin','accountant','viewer')),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
  id SERIAL PRIMARY KEY,
  type VARCHAR(10) NOT NULL CHECK (type IN ('income','expense')),
  amount NUMERIC(12,2) NOT NULL,
  category VARCHAR(50),
  account VARCHAR(50) DEFAULT 'cash',
  party VARCHAR(100),
  note TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Grant privileges to app user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO officeflow;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO officeflow;

CREATE TABLE IF NOT EXISTS invoices (
  id SERIAL PRIMARY KEY,
  client_name VARCHAR(100) NOT NULL,
  items JSONB,
  total NUMERIC(12,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'unpaid' CHECK (status IN ('paid','unpaid','overdue')),
  due_date DATE,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);
