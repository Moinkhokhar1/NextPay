function normalizePhone(phone) {
  if (!phone || typeof phone !== "string") {
    return null;
  }

  let cleaned = phone.trim().replace(/[\s\-()]/g, "");

  if (cleaned.startsWith("+")) {
    return cleaned;
  }

  if (cleaned.startsWith("91") && cleaned.length === 12) {
    return `+${cleaned}`;
  }

  if (/^\d{10}$/.test(cleaned)) {
    return `+91${cleaned}`;
  }

  return null;
}

module.exports = { normalizePhone };
