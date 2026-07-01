require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./config/db');

const authRoutes        = require('./routes/auth');
const transactionRoutes = require('./routes/transactions');
const invoiceRoutes     = require('./routes/invoices');
const reportRoutes      = require('./routes/reports');
const userRoutes        = require('./routes/users');
const partyRoutes       = require('./routes/parties');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/v1/auth',         authRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/invoices',     invoiceRoutes);
app.use('/api/v1/reports',      reportRoutes);
app.use('/api/v1/users',        userRoutes);
app.use('/api/v1/parties',      partyRoutes);

app.get('/',       (req, res) => res.json({ message: 'OfficeFlow API running' }));
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// ─── Auto-migrations (idempotent — safe to run on every startup) ──────────────
async function runMigrations() {
  const steps = [
    // party_id on transactions
    `ALTER TABLE transactions
       ADD COLUMN IF NOT EXISTS party_id INTEGER REFERENCES parties(id) ON DELETE SET NULL`,
    // party_id on invoices
    `ALTER TABLE invoices
       ADD COLUMN IF NOT EXISTS party_id INTEGER REFERENCES parties(id) ON DELETE SET NULL`,
    // invoice_number column
    `ALTER TABLE invoices
       ADD COLUMN IF NOT EXISTS invoice_number VARCHAR(20)`,
    // sequence for invoice numbers
    `CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1`,
    // backfill any existing invoices that have no number
    `UPDATE invoices
       SET invoice_number = 'INV-' || LPAD(nextval('invoice_number_seq')::TEXT, 4, '0')
       WHERE invoice_number IS NULL`,
    // trigger function
    `CREATE OR REPLACE FUNCTION set_invoice_number()
     RETURNS TRIGGER AS $$
     BEGIN
       IF NEW.invoice_number IS NULL THEN
         NEW.invoice_number := 'INV-' || LPAD(nextval('invoice_number_seq')::TEXT, 4, '0');
       END IF;
       RETURN NEW;
     END;
     $$ LANGUAGE plpgsql`,
    // drop + recreate trigger so it's always current
    `DROP TRIGGER IF EXISTS trg_invoice_number ON invoices`,
    `CREATE TRIGGER trg_invoice_number
       BEFORE INSERT ON invoices
       FOR EACH ROW EXECUTE FUNCTION set_invoice_number()`,
  ];

  for (const sql of steps) {
    try {
      await db.query(sql);
    } catch (e) {
      // Non-fatal — log and continue (e.g. column already exists)
      console.warn('Migration warning:', e.message);
    }
  }
  console.log('✅ Migrations complete.');
}

// ─── Start server ─────────────────────────────────────────────────────────────
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

  // Run DB migrations on startup
  await runMigrations();

  // Keep Render free tier awake — ping /health every 10 minutes.
  // (GitHub Actions cron also does this externally as a backup.)
  const PING_INTERVAL = 10 * 60 * 1000;
  const SELF_URL = process.env.RENDER_EXTERNAL_URL
    ? `${process.env.RENDER_EXTERNAL_URL}/health`
    : `http://localhost:${PORT}/health`;

  setInterval(() => {
    try {
      const mod = SELF_URL.startsWith('https') ? require('https') : require('http');
      mod.get(SELF_URL, (r) => r.resume()).on('error', () => {});
    } catch (_) {}
  }, PING_INTERVAL);
});
