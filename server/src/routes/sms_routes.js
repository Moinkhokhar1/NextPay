/**
 * OfflinePay — SMS Payment Backend Routes (Prisma)
 * Matched exactly to your schema.prisma
 */

const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// ── Internal API key middleware ───────────────────────────────
function requireInternalKey(req, res, next) {
  const key = req.headers['x-api-key'];
  if (!key || key !== process.env.BACKEND_API_KEY) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
}

// ─────────────────────────────────────────────────────────────
// ENDPOINT 1: GET /api/users/:id/sms-key
// ─────────────────────────────────────────────────────────────
router.get('/users/:id/sms-key', requireInternalKey, async (req, res) => {
  try {
    const { id } = req.params;

    let user = await prisma.user.findUnique({
      where: { id },
      select: { id: true, sms_secret_key: true },
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (!user.sms_secret_key) {
      const newKey = crypto.randomBytes(32).toString('hex');
      user = await prisma.user.update({
        where: { id },
        data: { sms_secret_key: newKey },
        select: { id: true, sms_secret_key: true },
      });
    }

    return res.json({ success: true, secretKey: user.sms_secret_key });
  } catch (err) {
    console.error('[GET /users/:id/sms-key]', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 2: POST /api/wallet/sms-transfer
// ─────────────────────────────────────────────────────────────
router.post('/wallet/sms-transfer', requireInternalKey, async (req, res) => {
  const { senderId, receiverId, amount } = req.body;

  if (!senderId || !receiverId || !amount) {
    return res.status(400).json({ success: false, message: 'Missing fields' });
  }

  const numericAmount = parseFloat(amount);
  if (isNaN(numericAmount) || numericAmount <= 0) {
    return res.status(400).json({ success: false, message: 'Invalid amount' });
  }

  if (senderId === receiverId) {
    return res.status(400).json({ success: false, message: 'Cannot transfer to yourself' });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {

      // ── Fetch users (now includes phone) ──────────────────
      const sender = await tx.user.findUnique({
        where: { id: senderId },
        select: { id: true, name: true, phone: true },
      });
      const receiver = await tx.user.findUnique({
        where: { id: receiverId },
        select: { id: true, name: true, phone: true },
      });

      if (!sender) throw new Error('Sender not found');
      if (!receiver) throw new Error('Receiver not found');
      if (!receiver.phone) throw new Error('Receiver has no phone number registered');

      // ── Fetch wallets ─────────────────────────────────────
      const senderWallet = await tx.wallet.findUnique({
        where: { user_id: senderId },
      });
      const receiverWallet = await tx.wallet.findUnique({
        where: { user_id: receiverId },
      });

      if (!senderWallet) throw new Error('Sender wallet not found');
      if (!receiverWallet) throw new Error('Receiver wallet not found');

      // ── Check balance ─────────────────────────────────────
      const available = parseFloat(senderWallet.balance) - senderWallet.locked_balance;
      if (available < numericAmount) throw new Error('Insufficient balance');

      // ── Debit sender ──────────────────────────────────────
      await tx.wallet.update({
        where: { user_id: senderId },
        data: { balance: parseFloat(senderWallet.balance) - numericAmount },
      });

      // ── Credit receiver ───────────────────────────────────
      await tx.wallet.update({
        where: { user_id: receiverId },
        data: { balance: parseFloat(receiverWallet.balance) + numericAmount },
      });

      // ── Record transaction ────────────────────────────────
      const nonce = BigInt(Date.now());
      const signature = crypto
        .createHash('sha256')
        .update(`${senderId}:${receiverId}:${numericAmount}:${nonce}`)
        .digest('hex');

      await tx.transaction.create({
        data: {
          sender_id: senderId,
          receiver_id: receiverId,
          amount: numericAmount,
          status: 'completed',
          nonce,
          signature,
          is_offline: true,
        },
      });

      return {
        senderName: sender.name,
        senderPhone: sender.phone,
        receiverName: receiver.name,
        receiverPhone: receiver.phone,  // real phone from DB
      };
    });

    return res.json({
      success: true,
      senderName: result.senderName,
      senderPhone: result.senderPhone,
      receiverName: result.receiverName,
      receiverPhone: result.receiverPhone,
      amount: numericAmount.toFixed(2),
    });

  } catch (err) {
    console.error('[POST /wallet/sms-transfer]', err.message);
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 3: POST /api/users/sync-sms-key
// ─────────────────────────────────────────────────────────────
router.post('/users/sync-sms-key', async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });

    const { secretKey } = req.body;
    if (!secretKey || secretKey.length < 16) {
      return res.status(400).json({ success: false, message: 'Invalid secret key' });
    }

    await prisma.user.update({
      where: { id: userId },
      data: { sms_secret_key: secretKey },
    });

    return res.json({ success: true, message: 'SMS key synced' });
  } catch (err) {
    console.error('[POST /users/sync-sms-key]', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 4: POST /api/users/register-phone
// Flutter calls this to save user's phone number
// Call this after login when phone is available
// ─────────────────────────────────────────────────────────────
router.post('/users/register-phone', async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });

    const { phone } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone required' });

    // Normalize to E.164 format e.g. +917201074880
    const normalized = phone.startsWith('+') ? phone : `+91${phone}`;

    await prisma.user.update({
      where: { id: userId },
      data: { phone: normalized },
    });

    return res.json({ success: true, message: 'Phone registered' });
  } catch (err) {
    // Unique constraint = number already taken
    if (err.code === 'P2002') {
      return res.status(400).json({ success: false, message: 'Phone already registered to another account' });
    }
    console.error('[POST /users/register-phone]', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;