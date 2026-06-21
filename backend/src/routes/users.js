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

router.delete('/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  if (String(req.user.id) === String(req.params.id))
    return res.status(400).json({ message: 'Cannot delete your own account' });
  await db.query('DELETE FROM users WHERE id=$1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
