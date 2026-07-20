// ─── SoundBox Configuration ────────────────────────────────────────────────
// ⚠️  Edit API_BASE_URL to match your offline-payment backend

/** Your backend base URL — no trailing slash */
// export const API_BASE_URL = "http://172.20.10.4:8000/api";
export const API_BASE_URL = "http://localhost:8000/api";

/** Poll interval in ms. 4000 = every 4 seconds */
export const POLL_INTERVAL_MS = 4000;

/** AsyncStorage key for the merchant JWT token */
export const MERCHANT_TOKEN_KEY = "token";