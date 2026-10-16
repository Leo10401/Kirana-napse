# Kirana-Napse Backend (FastAPI + MongoDB / MongoDB Atlas)

AI-Powered Demand Forecasting & Reorder Assistant for Kirana Stores.

## Features
- **Phone & Password Authentication** with JWT token issuance (`/api/v1/auth/register`, `/api/v1/auth/login`)
- **Statistical & ML Demand Forecasting Engine** (Holt-Winters, SARIMAX, LightGBM, dynamic cold-start blending)
- **Daily Reorder & Overstock Recommendations** (`/api/v1/stores/{id}/recommendations/today`, PATCH `/recommendations/{id}`)
- **Owner Feedback Loop** (`/api/v1/recommendations/{id}/flag`)
- **Distributor Order List Export** (`/api/v1/stores/{id}/export/distributor-list`)
- **Bill Photo OCR Pipeline** (`/api/v1/stores/{id}/bills/photo`, `/api/v1/bills/jobs/{id}`)
- **FCM Device Token & Install Event Tracking** (`/api/v1/stores/{id}/device-tokens`, `/api/v1/stores/{id}/install-events`)
- **Festival Calendar Seeder** with 16 national & regional festivals + monthly payday surge multipliers
- **Render Keep-Alive Heartbeat Job** (Automated ping every 3-4 minutes to prevent free-tier spin-down)

---

## Quick Start

### 1. Configure MongoDB Atlas (or local MongoDB)
Edit `.env` or set `MONGODB_URL`:
```env
MONGODB_URL=mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority
MONGODB_DB_NAME=kirana_napse
```

### 2. Run the Backend Locally
```bash
# In backend/ directory:
venv\Scripts\uvicorn.exe main:app --reload --port 8000
```
API Documentation (Swagger UI): http://localhost:8000/docs  
Health Check: http://localhost:8000/health

### 3. Seed Demo Store & Run Forecast
```bash
venv\Scripts\python.exe -m app.db.seed_demo
```
Log in with `+919876543210` / `password123` (also prefilled in the Flutter login screen). The seed prepares 10 catalog items, current stock, 21 days of sales per item, and fresh low-stock, reorder, overstock, and expiry recommendations. Run it again before a presentation to refresh dates and recommendations. It resets the known demo products' stock and generated recommendations while retaining manually entered sales and any other store's data.

### 4. Run Backtesting Validation Harness
```bash
venv\Scripts\python.exe -m scripts.run_backtest
```

---

## Render Deployment & Keep-Alive Configuration

Render's free web services spin down after 15 minutes of inactivity. To keep your server active and prevent cold-start delays:

### Option A: Automatic Built-in Heartbeat Worker (Recommended)
Render automatically exposes your public app URL in the environment variable `RENDER_EXTERNAL_URL`.

When deployed on Render, the backend automatically detects `RENDER_EXTERNAL_URL` and starts an internal `asyncio` heartbeat worker in the background that sends a `GET /health` request every **3.5 minutes (210 seconds)**.

To customize the interval or target URL, set these environment variables in your **Render Dashboard → Environment**:
```env
# Optional overrides:
KEEP_ALIVE_URL=https://your-app-name.onrender.com
KEEP_ALIVE_INTERVAL_SECONDS=210
KEEP_ALIVE_ENABLED=true
```

### Option B: Standalone External Pinger
You can also run the standalone keep-alive pinger from any remote cron runner or terminal:
```bash
venv\Scripts\python.exe -m scripts.keep_alive_pinger --url https://your-app-name.onrender.com --interval 210
```
