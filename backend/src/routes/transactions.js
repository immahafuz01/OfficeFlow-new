const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.get('/', auth, async (req, res) => {
  const result = await db.query('SELECT * FROM transactions ORDER BY date DESC');
  res.json(result.rows);
});

router.post('/', auth, async (req, res) => {
  const { type, amount, category, account, party, note, date } = req.body;
  try {
    const result = await db.query(
      'INSERT INTO transactions (type,amount,category,account,party,note,date,created_by) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *',
      [type, amount, category, account, party, note, date, req.user.id]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

router.delete('/:id', auth, async (req, res) => {
  await db.query('DELETE FROM transactions WHERE id=$1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
