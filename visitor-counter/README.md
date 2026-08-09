# Visitor Counter (monorepo)

This repository is reorganized into two folders:

- `backend/` - FastAPI backend and tests.
- `frontend/` - static frontend assets and image folders.

Backend quick start:

```bash
cd backend
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Frontend quick start (simple server):

```bash
cd frontend
python3 -m http.server 8001
# open http://localhost:8001
```

Run frontend tests:

```bash
cd frontend
npm test
```

Run both services with Docker Compose:

```bash
docker compose up --build
```

To run the services in the background (detached mode):

```bash
docker compose up --build -d
```

Backend will be available at http://localhost:8000
Front-end will be available at http://localhost:8001

Put multiple image folders under `frontend/images/` to serve different sets later.
