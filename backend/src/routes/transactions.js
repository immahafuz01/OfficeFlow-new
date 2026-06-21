const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

// GET /transactions?type=income&limit=20&offset=0
router.get('/', auth, async (req, res) => {
  const { type, limit = 20, offset = 0 } = req.query;
  try {
    const conditions = type ? 'WHERE type=$1' : '';
    const params = type
      ? [type, limit, offset]
      : [limit, offset];
    const limitIdx = type ? '$2' : '$1';
    const offsetIdx = type ? '$3' : '$2';

    const result = await db.query(
      `SELECT * FROM transactions ${conditions}
       ORDER BY date DESC, created_at DESC
       LIMIT ${limitIdx} OFFSET ${offsetIdx}`,
      params
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// POST /transactions
router.post('/', auth, async (req, res) => {
  const { type, amount, category, account = 'cash', party, note, date } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO transactions (type,amount,category,account,party,note,date,created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [type, amount, category, account, party, note, date, req.user.id]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

// DELETE /transactions/:id
router.delete('/:id', auth, async (req, res) => {
  await db.query('DELETE FROM transactions WHERE id=$1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
