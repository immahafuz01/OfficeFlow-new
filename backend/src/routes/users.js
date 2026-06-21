const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.get('/', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  const result = await db.query('SELECT id,name,email,role,created_at FROM users');
  res.json(result.rows);
});

router.patch('/:id/role', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  const result = await db.query('UPDATE users SET role=$1 WHERE id=$2 RETURNING id,name,email,role', [req.body.role, req.params.id]);
  res.json(result.rows[0]);
});

module.exports = router;
