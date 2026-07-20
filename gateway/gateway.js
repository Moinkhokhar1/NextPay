/**
 * OfflinePay SMS Gateway Server
 * ─────────────────────────────
 * Receives payment SMS from Twilio webhook, validates HMAC,
 * processes transfer via your existing backend API,
 * then sends confirmation SMSes to both sender and receiver.
 *
 * Stack: Node.js + Express + Twilio
 *
 * Setup:
 *   npm install express twilio axios crypto dotenv body-parser
 *
 * .env file:
 *   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxx
 *   TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxx
 *   TWILIO_PHONE_NUMBER=+917201074880      ← your number for now
 *   BACKEND_API_URL=https://your-api.com
 *   BACKEND_API_KEY=your_internal_api_key
 *   HMAC_SECRET_STORE_URL=https://your-api.com/users/secret-key
 *
 * Run: node gateway.js
 * Expose publicly: ngrok http 3000  (for testing)
 * Set Twilio webhook to: https://your-ngrok-url/sms/incoming
 */

require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const twilio = require('twilio');
const axios = require('axios');
const crypto = require('crypto');

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);
const GATEWAY_NUMBER = process.env.TWILIO_PHONE_NUMBER;
const BACKEND_URL = process.env.BACKEND_API_URL;
const BACKEND_KEY = process.env.BACKEND_API_KEY;

// In-memory nonce store (use Redis in production)
const usedNonces = new Set();

// ─── Main SMS webhook ─────────────────────────────────────────
app.post('/sms/incoming', async (req, res) => {
  const from = req.body.From || '';   // sender's phone number
  const body = (req.body.Body || '').trim();

  console.log(`[SMS] From: ${from} | Body: ${body}`);

  // Only process PAY# messages
  if (!body.startsWith('PAY#')) {
    return res.status(200).send('<Response></Response>');
  }

  try {
    const result = await processPaymentSms(from, body);

    if (result.success) {
      // Send confirmation to receiver
      await sendSms(result.receiverPhone, `PAY_CONFIRM#${result.amount}#${result.senderName}`);
      // Send receipt to sender
      await sendSms(from, `RECEIPT#Payment of Rs.${result.amount} sent to ${result.receiverName} successfully.`);
      console.log(`[OK] Payment processed: ${result.amount} from ${result.senderName} to ${result.receiverName}`);
    } else {
      // Notify sender of failure
      await sendSms(from, `FAILED#${result.error}`);
      console.log(`[FAIL] ${result.error}`);
    }
  } catch (err) {
    console.error('[ERROR]', err.message);
    await sendSms(from, 'FAILED#Server error. Please try again.');
  }

  // Always respond 200 to Twilio
  res.status(200).send('<Response></Response>');
});

// ─── Core payment processor ───────────────────────────────────
async function processPaymentSms(fromPhone, smsBody) {
  // 1. Parse payload: PAY#senderId#receiverId#amount#timestamp#hmac
  const parts = smsBody.split('#');
  if (parts.length !== 6) return { success: false, error: 'Invalid payment format.' };

  const [, senderId, receiverId, amountStr, timestampStr, receivedHmac] = parts;
  const amount = parseFloat(amountStr);
  const timestamp = parseInt(timestampStr, 10);

  if (isNaN(amount) || amount <= 0) return { success: false, error: 'Invalid amount.' };

  // 2. Replay protection — reject if older than 120 seconds
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > 120) {
    return { success: false, error: 'Payment expired. Please retry.' };
  }

  // 3. Nonce check — prevent exact duplicate SMS
  const nonce = `${senderId}:${receiverId}:${amountStr}:${timestampStr}`;
  if (usedNonces.has(nonce)) {
    return { success: false, error: 'Duplicate transaction detected.' };
  }

  // 4. Fetch sender's secret key from backend
  let senderSecretKey;
  try {
    const keyRes = await axios.get(`${BACKEND_URL}/users/${senderId}/sms-key`, {
      headers: { 'x-api-key': BACKEND_KEY },
    });
    senderSecretKey = keyRes.data.secretKey;
  } catch {
    return { success: false, error: 'Could not verify sender identity.' };
  }

  // 5. Verify HMAC
  const raw = `${senderId}:${receiverId}:${amountStr}:${timestampStr}`;
  const expectedHmac = crypto
    .createHmac('sha256', senderSecretKey)
    .update(raw)
    .digest('hex')
    .substring(0, 16);

  if (expectedHmac !== receivedHmac) {
    return { success: false, error: 'Invalid signature. Payment rejected.' };
  }

  // 6. Mark nonce as used
  usedNonces.add(nonce);
  setTimeout(() => usedNonces.delete(nonce), 5 * 60 * 1000); // clean up after 5 min

  // 7. Call backend to transfer funds
  let transferRes;
  try {
    transferRes = await axios.post(
      `${BACKEND_URL}/wallet/sms-transfer`,
      { senderId, receiverId, amount },
      { headers: { 'x-api-key': BACKEND_KEY } }
    );
  } catch (err) {
    const msg = err.response?.data?.message || 'Transfer failed.';
    return { success: false, error: msg };
  }

  if (!transferRes.data.success) {
    return { success: false, error: transferRes.data.message || 'Transfer failed.' };
  }

  return {
    success: true,
    amount: amount.toFixed(2),
    senderName: transferRes.data.senderName,
    receiverName: transferRes.data.receiverName,
    receiverPhone: transferRes.data.receiverPhone,
  };
}

// ─── SMS sender helper ────────────────────────────────────────
async function sendSms(to, message) {
  try {
    await twilioClient.messages.create({
      body: message,
      from: GATEWAY_NUMBER,
      to: to,
    });
    console.log(`[SMS SENT] To: ${to} | ${message}`);
  } catch (err) {
    console.error(`[SMS FAIL] To: ${to} | ${err.message}`);
  }
}

// ─── Health check ─────────────────────────────────────────────
app.get('/health', (_, res) => res.json({ status: 'ok', gateway: GATEWAY_NUMBER }));

// ─── Start ────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`OfflinePay SMS Gateway running on port ${PORT}`);
  console.log(`Gateway number: ${GATEWAY_NUMBER}`);
  console.log(`Twilio webhook URL: POST /sms/incoming`);
});