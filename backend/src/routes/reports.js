const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

// GET /reports/summary?from=&to=
// Returns today's income/expense, total balance, and monthly breakdown
router.get('/summary', auth, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const [todayRes, balanceRes, monthlyRes] = await Promise.all([
      // Today's totals
      db.query(
        `SELECT type, COALESCE(SUM(amount),0)::FLOAT AS total
         FROM transactions WHERE date = $1 GROUP BY type`,
        [today]
      ),
      // All-time balance
      db.query(
        `SELECT type, COALESCE(SUM(amount),0)::FLOAT AS total
         FROM transactions GROUP BY type`
      ),
      // Last 6 months monthly breakdown
      db.query(
        `SELECT TO_CHAR(date,'YYYY-MM') AS month, type, COALESCE(SUM(amount),0)::FLOAT AS total
         FROM transactions
         WHERE date >= NOW() - INTERVAL '6 months'
         GROUP BY month, type
         ORDER BY month ASC`
      ),
    ]);

    const pick = (rows, type) =>
      Number(rows.find(r => r.type === type)?.total || 0);

    const todayIncome  = pick(todayRes.rows, 'income');
    const todayExpense = pick(todayRes.rows, 'expense');
    const totalIncome  = pick(balanceRes.rows, 'income');
    const totalExpense = pick(balanceRes.rows, 'expense');

    res.json({
      today:   { income: todayIncome, expense: todayExpense },
      balance: totalIncome - totalExpense,
      monthly: monthlyRes.rows,
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET /reports/profit-loss?month=6&year=2026
router.get('/profit-loss', auth, async (req, res) => {
  const { month, year } = req.query;
  try {
    const result = await db.query(
      `SELECT type, COALESCE(SUM(amount),0)::FLOAT AS total FROM transactions
       WHERE EXTRACT(MONTH FROM date)=$1 AND EXTRACT(YEAR FROM date)=$2 GROUP BY type`,
      [month, year]
    );
    const income  = Number(result.rows.find(r => r.type === 'income')?.total  || 0);
    const expense = Number(result.rows.find(r => r.type === 'expense')?.total || 0);
    res.json({ income, expense, profit: income - expense });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
