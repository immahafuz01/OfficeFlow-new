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

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
