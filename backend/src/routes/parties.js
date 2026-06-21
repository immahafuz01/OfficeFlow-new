const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

// GET /parties — list all with computed balance
router.get('/', auth, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT p.*,
        COALESCE(p.opening_balance, 0)::FLOAT
          + COALESCE(SUM(CASE WHEN t.type='income'  THEN t.amount ELSE 0 END), 0)::FLOAT
          - COALESCE(SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END), 0)::FLOAT
        AS balance
      FROM parties p
      LEFT JOIN transactions t ON t.party_id = p.id
      GROUP BY p.id
      ORDER BY p.name ASC
    `);
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// POST /parties
router.post('/', auth, async (req, res) => {
  const { name, phone, type = 'customer', opening_balance = 0, notes } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO parties (name,phone,type,opening_balance,notes,created_by)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [name, phone, type, opening_balance, notes, req.user.id]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// PATCH /parties/:id
router.patch('/:id', auth, async (req, res) => {
  const { name, phone, type, opening_balance, notes } = req.body;
  try {
    const result = await db.query(
      `UPDATE parties SET
         name=COALESCE($1,name),
         phone=COALESCE($2,phone),
         type=COALESCE($3,type),
         opening_balance=COALESCE($4,opening_balance),
         notes=COALESCE($5,notes)
       WHERE id=$6 RETURNING *`,
      [name, phone, type, opening_balance, notes, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// DELETE /parties/:id
router.delete('/:id', auth, async (req, res) => {
  await db.query('DELETE FROM parties WHERE id=$1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

// GET /parties/:id/ledger — full transaction history + running balance
router.get('/:id/ledger', auth, async (req, res) => {
  try {
    const partyRes = await db.query('SELECT * FROM parties WHERE id=$1', [req.params.id]);
    if (!partyRes.rows.length) return res.status(404).json({ message: 'Not found' });
    const party = partyRes.rows[0];

    const txRes = await db.query(
      `SELECT id, type, amount::FLOAT, category, account, note, date::TEXT
       FROM transactions WHERE party_id=$1 ORDER BY date ASC, created_at ASC`,
      [req.params.id]
    );

    // Compute running balance
    let running = Number(party.opening_balance);
    const rows = txRes.rows.map(tx => {
      running += tx.type === 'income' ? tx.amount : -tx.amount;
      return { ...tx, running_balance: parseFloat(running.toFixed(2)) };
    });

    res.json({
      party: { ...party, opening_balance: Number(party.opening_balance) },
      transactions: rows,
      balance: parseFloat(running.toFixed(2)),
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
