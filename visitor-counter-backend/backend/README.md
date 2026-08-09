# Visitor Counter Backend

A simple FastAPI backend for a visitor counter application.

## Project structure

- `app/` - Python package containing the FastAPI application.
- `app/main.py` - FastAPI entrypoint where endpoints are defined.
- `requirements.txt` - Python dependencies for the project.
- `.gitignore` - Files and directories to ignore in Git.

## Endpoints

- `GET /health` - returns service health status.
- `GET /counter` - returns a hardcoded visitor count of `1`.
- `POST /increment` - placeholder response for incrementing the counter.
- `POST /reset` - placeholder response for resetting the counter.

## Setup

### 1. Create a virtual environment

```bash
python3.13 -m venv .venv
```

### 2. Activate the virtual environment

```bash
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Start the FastAPI server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
