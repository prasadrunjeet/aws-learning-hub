# Frontend

This folder contains the static frontend for the visitor counter application.

## Local setup

Install dependencies:

```bash
cd frontend
npm install
```

Start a simple local server:

```bash
cd frontend
python3 -m http.server 8001
```

Open the app in your browser:

```text
http://localhost:8001
```

## Run tests

```bash
cd frontend
npm test
```

The tests cover the frontend API helpers and DOM update logic.

## Optional image folders

If you want to add images later, place them in subfolders under `frontend/images/`, for example:

- `frontend/images/landscape/`
- `frontend/images/portraits/`

The current frontend UI is focused on the visitor counter API.
