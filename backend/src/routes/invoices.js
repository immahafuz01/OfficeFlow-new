const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

// Helper: auto-mark overdue invoices before any read
async function markOverdue() {
  await db.query(`
    UPDATE invoices
    SET status = 'overdue'
    WHERE status = 'unpaid' AND due_date < CURRENT_DATE
  `);
}

// GET /invoices — list with optional filters: status, party_id
router.get('/', auth, async (req, res) => {
  try {
    await markOverdue();
    const { status, party_id } = req.query;
    const conditions = [];
    const params = [];

    if (status) {
      params.push(status);
      conditions.push(`i.status = $${params.length}`);
    }
    if (party_id) {
      params.push(party_id);
      conditions.push(`i.party_id = $${params.length}`);
    }

    const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';

    const result = await db.query(`
      SELECT
        i.*,
        i.total::FLOAT AS total,
        p.name AS party_name,
        p.type AS party_type
      FROM invoices i
      LEFT JOIN parties p ON p.id = i.party_id
      ${where}
      ORDER BY i.created_at DESC
    `, params);

    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET /invoices/:id — single invoice with party info
router.get('/:id', auth, async (req, res) => {
  try {
    await markOverdue();
    const result = await db.query(`
      SELECT
        i.*,
        i.total::FLOAT AS total,
        p.name AS party_name,
        p.type AS party_type,
        p.phone AS party_phone
      FROM invoices i
      LEFT JOIN parties p ON p.id = i.party_id
      WHERE i.id = $1
    `, [req.params.id]);

    if (!result.rows.length) return res.status(404).json({ message: 'Not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// POST /invoices — create
router.post('/', auth, async (req, res) => {
  const { client_name, items, total, status = 'unpaid', due_date, party_id } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO invoices (client_name, items, total, status, due_date, party_id, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *, total::FLOAT AS total`,
      [client_name, JSON.stringify(items), total, status, due_date, party_id || null, req.user.id]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// PATCH /invoices/:id — full edit (client_name, items, total, due_date, party_id, status)
router.patch('/:id', auth, async (req, res) => {
  const { client_name, items, total, status, due_date, party_id } = req.body;
  try {
    const result = await db.query(
      `UPDATE invoices SET
        client_name = COALESCE($1, client_name),
        items       = COALESCE($2, items),
        total       = COALESCE($3, total),
        status      = COALESCE($4, status),
        due_date    = COALESCE($5, due_date),
        party_id    = CASE WHEN $6::INTEGER IS NOT NULL THEN $6::INTEGER ELSE party_id END
      WHERE id = $7
      RETURNING *, total::FLOAT AS total`,
      [
        client_name || null,
        items ? JSON.stringify(items) : null,
        total || null,
        status || null,
        due_date || null,
        party_id ?? null,
        req.params.id,
      ]
    );
    if (!result.rows.length) return res.status(404).json({ message: 'Not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// PATCH /invoices/:id/status — quick status-only update (kept for backward compat)
router.patch('/:id/status', auth, async (req, res) => {
  const { status } = req.body;
  try {
    const result = await db.query(
      `UPDATE invoices SET status = $1 WHERE id = $2 RETURNING *, total::FLOAT AS total`,
      [status, req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ message: 'Not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// DELETE /invoices/:id
router.delete('/:id', auth, async (req, res) => {
  await db.query('DELETE FROM invoices WHERE id = $1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
