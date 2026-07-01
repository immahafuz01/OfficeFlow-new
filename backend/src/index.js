require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const transactionRoutes = require('./routes/transactions');
const invoiceRoutes = require('./routes/invoices');
const reportRoutes = require('./routes/reports');
const userRoutes = require('./routes/users');
const partyRoutes = require('./routes/parties');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/invoices', invoiceRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/parties', partyRoutes);

app.get('/', (req, res) => res.json({ message: 'OfficeFlow API running' }));
app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);

  // Keep Render free tier awake by pinging /health every 10 minutes.
  // Render spins down after 15 min of inactivity — this prevents that.
  const PING_INTERVAL = 10 * 60 * 1000; // 10 minutes
  const SELF_URL = process.env.RENDER_EXTERNAL_URL
    ? `${process.env.RENDER_EXTERNAL_URL}/health`
    : `http://localhost:${PORT}/health`;

  setInterval(async () => {
    try {
      const https = require('https');
      const http  = require('http');
      const client = SELF_URL.startsWith('https') ? https : http;
      client.get(SELF_URL, (res) => {
        res.resume(); // drain response
      }).on('error', () => {}); // swallow errors silently
    } catch (_) {}
  }, PING_INTERVAL);
});
