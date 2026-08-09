export const backendBase = new URLSearchParams(window.location.search).get('backend') || 'http://localhost:8000';

export function getElements() {
  return {
    countEl: document.getElementById('count'),
    statusEl: document.getElementById('status'),
    refreshBtn: document.getElementById('refreshBtn'),
    incBtn: document.getElementById('incBtn'),
    resetBtn: document.getElementById('resetBtn'),
  };
}

export async function apiGet(path) {
  const res = await fetch(backendBase + path, { cache: 'no-store' });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function apiPost(path) {
  const res = await fetch(backendBase + path, { method: 'POST' });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function refreshCount(elements) {
  const { countEl, statusEl } = elements;
  try {
    statusEl.textContent = 'Fetching...';
    const data = await apiGet('/counter');
    countEl.textContent = data.count;
    statusEl.textContent = 'Updated';
  } catch (err) {
    statusEl.textContent = 'Error: ' + err.message;
    countEl.textContent = '—';
  }
}

export function initApp() {
  const elements = getElements();

  elements.refreshBtn.addEventListener('click', () => refreshCount(elements));

  elements.incBtn.addEventListener('click', async () => {
    try {
      elements.statusEl.textContent = 'Incrementing...';
      await apiPost('/increment');
      await refreshCount(elements);
    } catch (err) {
      elements.statusEl.textContent = 'Error: ' + err.message;
    }
  });

  elements.resetBtn.addEventListener('click', async () => {
    try {
      elements.statusEl.textContent = 'Resetting...';
      await apiPost('/reset');
      await refreshCount(elements);
    } catch (err) {
      elements.statusEl.textContent = 'Error: ' + err.message;
    }
  });

  refreshCount(elements);
  setInterval(() => refreshCount(elements), 5000);
}
