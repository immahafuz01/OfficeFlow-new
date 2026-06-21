const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.get('/summary', auth, async (req, res) => {
  const { from, to } = req.query;
  const result = await db.query(
    `SELECT type, SUM(amount) as total FROM transactions
     WHERE date BETWEEN $1 AND $2 GROUP BY type`,
    [from || '2000-01-01', to || 'now()']
  );
  res.json(result.rows);
});

router.get('/profit-loss', auth, async (req, res) => {
  const { month, year } = req.query;
  const result = await db.query(
    `SELECT type, SUM(amount) as total FROM transactions
     WHERE EXTRACT(MONTH FROM date)=$1 AND EXTRACT(YEAR FROM date)=$2 GROUP BY type`,
    [month, year]
  );
  const income = result.rows.find(r => r.type === 'income')?.total || 0;
  const expense = result.rows.find(r => r.type === 'expense')?.total || 0;
  res.json({ income, expense, profit: income - expense });
});

module.exports = router;
