# OfficeFlow

> Simplified Office Accounting – Smart, Secure & Always Up-to-Date

A complete accounting and financial management solution for small and medium-sized offices — available on Mobile (Android/iOS) and Web.

## Project Structure

```
├── app/          # Flutter app (Android, iOS, Web)
├── backend/      # Node.js + Express REST API
├── kiro.md       # Project memory file
└── brife.md      # Project brief
```

## Tech Stack

- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Node.js + Express
- **Database:** PostgreSQL
- **Auth:** JWT

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env   # fill in your values
npm install
npm run dev
```

### Flutter App
```bash
cd app
flutter pub get
flutter run
```

## API Endpoints

```
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/transactions
POST /api/v1/transactions
GET  /api/v1/invoices
POST /api/v1/invoices
GET  /api/v1/reports/summary
GET  /api/v1/reports/profit-loss
GET  /api/v1/users
```

## Development Phases

1. ✅ Project Setup
2. ⬜ UI/UX Design
3. 🔄 MVP Development
4. ⬜ Testing & QA
5. ⬜ Deployment
