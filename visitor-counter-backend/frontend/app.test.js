import { beforeEach, describe, expect, it, vi } from 'vitest';
import { apiGet, apiPost, getElements, refreshCount, initApp } from './app.js';

const originalFetch = global.fetch;
let elements;

beforeEach(() => {
  document.body.innerHTML = `
    <div id="count"></div>
    <div id="status"></div>
    <button id="refreshBtn"></button>
    <button id="incBtn"></button>
    <button id="resetBtn"></button>
  `;
  elements = getElements();
  global.fetch = vi.fn();
});

afterEach(() => {
  global.fetch = originalFetch;
});

describe('Frontend app', () => {
  it('should resolve apiGet when response ok', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ count: 5 }) });
    const res = await apiGet('/counter');
    expect(res).toEqual({ count: 5 });
  });

  it('should reject apiGet when response is not ok', async () => {
    global.fetch.mockResolvedValueOnce({ ok: false, text: async () => 'bad' });
    await expect(apiGet('/counter')).rejects.toThrow('bad');
  });

  it('should resolve apiPost when response ok', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ message: 'ok' }) });
    const res = await apiPost('/increment');
    expect(res).toEqual({ message: 'ok' });
  });

  it('should update the DOM after refreshCount', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ count: 7 }) });
    await refreshCount(elements);
    expect(elements.countEl.textContent).toBe('7');
    expect(elements.statusEl.textContent).toBe('Updated');
  });

  it('initializes event handlers in initApp', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ count: 10 }) });
    initApp();
    elements.incBtn.dispatchEvent(new MouseEvent('click'));
    expect(global.fetch).toHaveBeenCalled();
  });
});
