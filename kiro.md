# OfficeFlow — Project Memory File (kiro.md)

> This file is the persistent memory for the OfficeFlow project.
> Update after every phase/milestone. Never delete existing entries — append new ones.

---

## Project Overview

- **App Name:** OfficeFlow
- **Tagline:** "Simplified Office Accounting – Smart, Secure & Always Up-to-Date"
- **Purpose:** Complete accounting & financial management for small/medium offices
- **Target Market:** Bangladesh and similar markets (shops, offices, startups, coaching centers)
- **GitHub Repo:** https://github.com/immahafuz01/OfficeFlow-new.git

---

## Tech Stack

| Component   | Technology                        |
|-------------|-----------------------------------|
| Mobile App  | Flutter (Android + iOS)           |
| Web App     | Flutter Web                       |
| Backend     | Node.js + Express                 |
| Database    | PostgreSQL                        |
| Auth        | JWT                               |
| File Storage| Cloudinary / AWS S3               |
| Hosting     | Vercel / Render / DigitalOcean    |

---

## Project Structure

```
mahafuz.project/
├── brife.md              # Original project brief
├── kiro.md               # This memory file
├── README.md             # Project readme
├── app/                  # Flutter app (mobile + web)
└── backend/              # Node.js + Express API
```

---

## Core Features

### Phase 1 (MVP)
- Dashboard (real-time income/expense, cash flow chart, balance)
- Transaction Management (income/expense, cash & bank, categories, party ledger)
- Invoicing & Billing (create invoices, PDF, status tracking)
- Reports (P&L, Balance Sheet, Daily/Monthly/Yearly, PDF & Excel export)
- User & Role Management (Admin, Accountant, Viewer roles)

### Phase 2
- Employee payroll & salary management
- Basic inventory linking
- Bank reconciliation
- Dark mode
- Bengali + English language support

---

## Architecture Decisions

- **Single codebase (Flutter)** for both mobile and web for faster development
- **JWT auth** over Firebase for full control and no external dependency
- **PostgreSQL** for relational financial data integrity
- **REST API** (Node.js/Express) — can migrate to GraphQL in Phase 2 if needed

---

## Development Phases

| # | Phase                          | Status      |
|---|-------------------------------|-------------|
| 1 | Requirement & Planning        | ✅ Done      |
| 2 | UI/UX Design (Figma)          | ⬜ Pending   |
| 3 | MVP Development               | 🔄 In Progress |
| 4 | Testing & QA                  | ⬜ Pending   |
| 5 | Security & Backup             | ⬜ Pending   |
| 6 | Deployment (Play Store + Web) | ⬜ Pending   |
| 7 | Maintenance & Updates         | ⬜ Pending   |

---

## Environment Variables (Backend)

> Store actual values in `.env` (never commit to git)

```
PORT=3000
DATABASE_URL=postgresql://user:password@host:5432/officeflow
JWT_SECRET=<your-secret>
JWT_EXPIRES_IN=7d
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

---

## API Structure (Planned)

```
/api/v1/auth          → login, register, refresh
/api/v1/transactions  → CRUD income/expense
/api/v1/invoices      → CRUD invoices
/api/v1/reports       → generate reports
/api/v1/users         → user & role management
```

---

## Milestones Log

### 2026-06-21 — Project Setup
- Read project brief from brife.md
- Created kiro.md memory file
- Initialized Flutter app (`app/`)
- Initialized Node.js + Express backend (`backend/`)
- Set up project folder structure
- Initialized git and pushed to GitHub

---

## Notes & Decisions

- Flutter chosen over React.js for web to maintain single codebase with mobile
- `.gitignore` excludes `node_modules/`, `build/`, `.env`, and Flutter build artifacts
- All commits should follow: `feat:`, `fix:`, `chore:`, `docs:` prefixes

