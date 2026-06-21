const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.get('/', auth, async (req, res) => {
  const result = await db.query('SELECT * FROM invoices ORDER BY created_at DESC');
  res.json(result.rows);
});

router.post('/', auth, async (req, res) => {
  const { client_name, items, total, status = 'unpaid', due_date } = req.body;
  try {
    const result = await db.query(
      'INSERT INTO invoices (client_name,items,total,status,due_date,created_by) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [client_name, JSON.stringify(items), total, status, due_date, req.user.id]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

router.patch('/:id/status', auth, async (req, res) => {
  const { status } = req.body;
  const result = await db.query('UPDATE invoices SET status=$1 WHERE id=$2 RETURNING *', [status, req.params.id]);
  res.json(result.rows[0]);
});

module.exports = router;
