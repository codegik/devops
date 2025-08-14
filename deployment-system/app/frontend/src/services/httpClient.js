
const BASE_URL = `http://${process.env.BACKEND_HOST || 'localhost'}:${process.env.BACKEND_PORT || 3000}`;


const DEFAULT_TIMEOUT = 10000; // ms

function joinURL(base, path) {
  if (!base.endsWith('/') && !path.startsWith('/')) return `${base}/${path}`;
  if (base.endsWith('/') && path.startsWith('/')) return base + path.slice(1);
  return base + path;
}

async function request(path, { method = 'GET', headers = {}, body, timeout = DEFAULT_TIMEOUT, signal } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(new Error(`Request timeout after ${timeout}ms`)), timeout);

  const isFormData = typeof FormData !== 'undefined' && body instanceof FormData;
  const finalHeaders = {
    Accept: 'application/json',
    ...(!isFormData && body ? { 'Content-Type': 'application/json' } : {}),
    ...headers,
  };

  try {
    const res = await fetch(joinURL(BASE_URL, path), {
      method,
      headers: finalHeaders,
      body: isFormData ? body : body ? JSON.stringify(body) : undefined,
      signal: signal ?? controller.signal,
    });

    if (!res.ok) {
      // Try to extract error details
      const text = await res.text().catch(() => '');
      const err = new Error(`HTTP ${res.status} ${res.statusText} – ${text}`);
      err.status = res.status;
      err.body = text;
      throw err;
    }

    if (res.status === 204) return null;

    const ct = res.headers.get('content-type') || '';
    if (ct.includes('application/json')) return res.json();
    return res.text();
  } finally {
    clearTimeout(timer);
  }
}

export const http = {
  baseURL: BASE_URL,
  get: (path, opts) => request(path, { ...opts, method: 'GET' }),
  post: (path, body, opts) => request(path, { ...opts, method: 'POST', body }),
  put: (path, body, opts) => request(path, { ...opts, method: 'PUT', body }),
  patch: (path, body, opts) => request(path, { ...opts, method: 'PATCH', body }),
  delete: (path, opts) => request(path, { ...opts, method: 'DELETE' }),
};
