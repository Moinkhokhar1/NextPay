// /**
//  * OfflinePay — SMS Payment Backend Routes (Prisma)
//  * Matched exactly to your schema.prisma
//  */

// const express = require('express');
// const router = express.Router();
// const crypto = require('crypto');
// const { PrismaClient } = require('@prisma/client');

// const prisma = new PrismaClient();

// // ── Internal API key middleware ───────────────────────────────
// function requireInternalKey(req, res, next) {
//   const key = req.headers['x-api-key'];
//   if (!key || key !== process.env.BACKEND_API_KEY) {
//     return res.status(401).json({ success: false, message: 'Unauthorized' });
//   }
//   next();
// }

// // ─────────────────────────────────────────────────────────────
// // ENDPOINT 1: GET /api/users/:id/sms-key
// // ─────────────────────────────────────────────────────────────
// router.get('/users/:id/sms-key', requireInternalKey, async (req, res) => {
//   try {
//     const { id } = req.params;

//     let user = await prisma.user.findUnique({
//       where: { id },
//       select: { id: true, sms_secret_key: true },
//     });

//     if (!user) {
//       return res.status(404).json({ success: false, message: 'User not found' });
//     }

//     if (!user.sms_secret_key) {
//       const newKey = crypto.randomBytes(32).toString('hex');
//       user = await prisma.user.update({
//         where: { id },
//         data: { sms_secret_key: newKey },
//         select: { id: true, sms_secret_key: true },
//       });
//     }

//     return res.json({ success: true, secretKey: user.sms_secret_key });
//   } catch (err) {
//     console.error('[GET /users/:id/sms-key]', err);
//     return res.status(500).json({ success: false, message: 'Server error' });
//   }
// });

// // ─────────────────────────────────────────────────────────────
// // ENDPOINT 2: POST /api/wallet/sms-transfer
// // ─────────────────────────────────────────────────────────────
// router.post('/wallet/sms-transfer', requireInternalKey, async (req, res) => {
//   const { senderId, receiverId, amount } = req.body;

//   if (!senderId || !receiverId || !amount) {
//     return res.status(400).json({ success: false, message: 'Missing fields' });
//   }

//   const numericAmount = parseFloat(amount);
//   if (isNaN(numericAmount) || numericAmount <= 0) {
//     return res.status(400).json({ success: false, message: 'Invalid amount' });
//   }

//   if (senderId === receiverId) {
//     return res.status(400).json({ success: false, message: 'Cannot transfer to yourself' });
//   }

//   try {
//     const result = await prisma.$transaction(async (tx) => {

//       // ── Fetch users (now includes phone) ──────────────────
//       const sender = await tx.user.findUnique({
//         where: { id: senderId },
//         select: { id: true, name: true, phone: true },
//       });
//       const receiver = await tx.user.findUnique({
//         where: { id: receiverId },
//         select: { id: true, name: true, phone: true },
//       });

//       if (!sender) throw new Error('Sender not found');
//       if (!receiver) throw new Error('Receiver not found');
//       if (!receiver.phone) throw new Error('Receiver has no phone number registered');

//       // ── Fetch wallets ─────────────────────────────────────
//       const senderWallet = await tx.wallet.findUnique({
//         where: { user_id: senderId },
//       });
//       const receiverWallet = await tx.wallet.findUnique({
//         where: { user_id: receiverId },
//       });

//       if (!senderWallet) throw new Error('Sender wallet not found');
//       if (!receiverWallet) throw new Error('Receiver wallet not found');

//       // ── Check balance ─────────────────────────────────────
//       const available = parseFloat(senderWallet.balance) - senderWallet.locked_balance;
//       if (available < numericAmount) throw new Error('Insufficient balance');

//       // ── Debit sender ──────────────────────────────────────
//       await tx.wallet.update({
//         where: { user_id: senderId },
//         data: { balance: parseFloat(senderWallet.balance) - numericAmount },
//       });

//       // ── Credit receiver ───────────────────────────────────
//       await tx.wallet.update({
//         where: { user_id: receiverId },
//         data: { balance: parseFloat(receiverWallet.balance) + numericAmount },
//       });

//       // ── Record transaction ────────────────────────────────
//       const nonce = BigInt(Date.now());
//       const signature = crypto
//         .createHash('sha256')
//         .update(`${senderId}:${receiverId}:${numericAmount}:${nonce}`)
//         .digest('hex');

//       await tx.transaction.create({
//         data: {
//           sender_id: senderId,
//           receiver_id: receiverId,
//           amount: numericAmount,
//           status: 'completed',
//           nonce,
//           signature,
//           is_offline: true,
//         },
//       });

//       return {
//         senderName: sender.name,
//         senderPhone: sender.phone,
//         receiverName: receiver.name,
//         receiverPhone: receiver.phone,  // real phone from DB
//       };
//     });

//     return res.json({
//       success: true,
//       senderName: result.senderName,
//       senderPhone: result.senderPhone,
//       receiverName: result.receiverName,
//       receiverPhone: result.receiverPhone,
//       amount: numericAmount.toFixed(2),
//     });

//   } catch (err) {
//     console.error('[POST /wallet/sms-transfer]', err.message);
//     return res.status(400).json({ success: false, message: err.message });
//   }
// });

// // ─────────────────────────────────────────────────────────────
// // ENDPOINT 3: POST /api/users/sync-sms-key
// // ─────────────────────────────────────────────────────────────
// router.post('/users/sync-sms-key', async (req, res) => {
//   try {
//     const userId = req.user?.id;
//     if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });

//     const { secretKey } = req.body;
//     if (!secretKey || secretKey.length < 16) {
//       return res.status(400).json({ success: false, message: 'Invalid secret key' });
//     }

//     await prisma.user.update({
//       where: { id: userId },
//       data: { sms_secret_key: secretKey },
//     });

//     return res.json({ success: true, message: 'SMS key synced' });
//   } catch (err) {
//     console.error('[POST /users/sync-sms-key]', err);
//     return res.status(500).json({ success: false, message: 'Server error' });
//   }
// });

// // ─────────────────────────────────────────────────────────────
// // ENDPOINT 4: POST /api/users/register-phone
// // Flutter calls this to save user's phone number
// // Call this after login when phone is available
// // ─────────────────────────────────────────────────────────────
// router.post('/users/register-phone', async (req, res) => {
//   try {
//     const userId = req.user?.id;
//     if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });

//     const { phone } = req.body;
//     if (!phone) return res.status(400).json({ success: false, message: 'Phone required' });

//     // Normalize to E.164 format e.g. +917201074880
//     const normalized = phone.startsWith('+') ? phone : `+91${phone}`;

//     await prisma.user.update({
//       where: { id: userId },
//       data: { phone: normalized },
//     });

//     return res.json({ success: true, message: 'Phone registered' });
//   } catch (err) {
//     // Unique constraint = number already taken
//     if (err.code === 'P2002') {
//       return res.status(400).json({ success: false, message: 'Phone already registered to another account' });
//     }
//     console.error('[POST /users/register-phone]', err);
//     return res.status(500).json({ success: false, message: 'Server error' });
//   }
// });

// module.exports = router;
/**
 * OfflinePay — SMS Payment Backend Routes (Prisma)
 *
 * FIXES APPLIED vs. original:
 *   1. GET /users/:id/sms-key no longer auto-generates a secret on first
 *      call. A server-generated secret can never match whatever the client
 *      independently generated, which was silently breaking HMAC
 *      verification end-to-end. The client must sync its own key first via
 *      /users/sync-sms-key; until then this endpoint reports "not synced".
 *   2. authMiddleware attached to /users/sync-sms-key and
 *      /users/register-phone — both read req.user.id but had no
 *      authentication in front of them, so req.user was always undefined
 *      and both routes unconditionally 401'd.
 *   3. requireInternalKey now uses crypto.timingSafeEqual instead of `!==`.
 *   4. POST /wallet/sms-transfer debit is now a single atomic conditional
 *      UPDATE (raw SQL, since Prisma's query builder can't compare two
 *      columns — balance vs. locked_balance — in a WHERE clause). This
 *      closes the same check-then-act race that was in transferMoney: two
 *      concurrent SMS transfers from one wallet can no longer both pass.
 *   5. Uses the shared Prisma singleton instead of its own `new
 *      PrismaClient()` (avoids exhausting the connection pool alongside
 *      the other routers that were doing the same thing).
 *
 * STILL TRUE / not fixed here: the client's local HMAC secret is synced
 * over this same API, so a compromise of the sync channel compromises the
 * SMS channel too (see the earlier discussion on Option A vs Option B for
 * the SMS design).
 */

const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { Prisma } = require('@prisma/client');
const prisma = require('../config/db');
const authMiddleware = require('../middleware/authMiddleware');

// ── Internal API key middleware (constant-time comparison) ────
function requireInternalKey(req, res, next) {
  const provided = Buffer.from(req.headers['x-api-key'] ?? '', 'utf8');
  const expected = Buffer.from(process.env.BACKEND_API_KEY ?? '', 'utf8');

  const valid =
    provided.length === expected.length &&
    expected.length > 0 &&
    crypto.timingSafeEqual(provided, expected);

  if (!valid) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
}

// ─────────────────────────────────────────────────────────────
// ENDPOINT 1: GET /api/users/:id/sms-key
// Called by the gateway to fetch a sender's key for HMAC verification.
// Does NOT generate one — the client must have synced it first.
// ─────────────────────────────────────────────────────────────
router.get('/users/:id/sms-key', requireInternalKey, async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      select: { id: true, sms_secret_key: true },
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (!user.sms_secret_key) {
      // Do NOT generate a key here — the client owns key generation.
      // A server-generated fallback would never match the client's copy.
      return res.status(409).json({
        success: false,
        message: 'SMS key not yet synced for this user. Ask the app to sync it first.',
      });
    }

    return res.json({ success: true, secretKey: user.sms_secret_key });
  } catch (err) {
    console.error('[GET /users/:id/sms-key]', err.code || err.name);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 2: POST /api/wallet/sms-transfer
// Called by the gateway after it has independently verified the HMAC.
// ─────────────────────────────────────────────────────────────
router.post('/wallet/sms-transfer', requireInternalKey, async (req, res) => {
  const { senderId, receiverId, amount } = req.body;

  if (!senderId || !receiverId || !amount) {
    return res.status(400).json({ success: false, message: 'Missing fields' });
  }

  let numericAmount;
  try {
    numericAmount = new Prisma.Decimal(amount).toDecimalPlaces(2);
  } catch {
    return res.status(400).json({ success: false, message: 'Invalid amount' });
  }
  if (!numericAmount.isFinite() || numericAmount.lte(0)) {
    return res.status(400).json({ success: false, message: 'Invalid amount' });
  }

  if (senderId === receiverId) {
    return res.status(400).json({ success: false, message: 'Cannot transfer to yourself' });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
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

      const receiverWallet = await tx.wallet.findUnique({ where: { user_id: receiverId } });
      if (!receiverWallet) throw new Error('Receiver wallet not found');

      // Atomic, conditional debit in one statement: Postgres checks
      // (balance - locked_balance) >= amount as part of the same write
      // that performs it, so two concurrent SMS transfers from the same
      // sender can't both read a "sufficient" balance and both succeed.
      // Prisma's query builder can't express a column-vs-column
      // comparison in a WHERE clause, hence the raw SQL here.
      const debited = await tx.$executeRaw`
        UPDATE "Wallet"
        SET balance = balance - ${numericAmount}
        WHERE user_id = ${senderId}
          AND (balance - locked_balance) >= ${numericAmount}
      `;

      if (debited === 0) {
        // Either the sender has no wallet row, or balance was insufficient.
        const senderWallet = await tx.wallet.findUnique({ where: { user_id: senderId } });
        if (!senderWallet) throw new Error('Sender wallet not found');
        throw new Error('Insufficient balance');
      }

      await tx.wallet.update({
        where: { user_id: receiverId },
        data: { balance: { increment: numericAmount } },
      });

      const nonce = BigInt(Date.now()) * 1000n + BigInt(Math.floor(Math.random() * 1000));
      const signature = crypto
        .createHash('sha256')
        .update(`${senderId}:${receiverId}:${numericAmount.toString()}:${nonce}`)
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
        receiverPhone: receiver.phone,
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
    // Client-facing message stays generic-ish; full error only in logs.
    console.error('[POST /wallet/sms-transfer]', err.message);
    const knownErrors = [
      'Sender not found',
      'Receiver not found',
      'Receiver has no phone number registered',
      'Sender wallet not found',
      'Receiver wallet not found',
      'Insufficient balance',
    ];
    const message = knownErrors.includes(err.message) ? err.message : 'Transfer failed';
    return res.status(400).json({ success: false, message });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 3: POST /api/users/sync-sms-key   (requires login)
// ─────────────────────────────────────────────────────────────
router.post('/users/sync-sms-key', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const { secretKey } = req.body;
    if (!secretKey || typeof secretKey !== 'string' || secretKey.length < 16) {
      return res.status(400).json({ success: false, message: 'Invalid secret key' });
    }

    await prisma.user.update({
      where: { id: userId },
      data: { sms_secret_key: secretKey },
    });

    return res.json({ success: true, message: 'SMS key synced' });
  } catch (err) {
    console.error('[POST /users/sync-sms-key]', err.code || err.name);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ─────────────────────────────────────────────────────────────
// ENDPOINT 4: POST /api/users/register-phone   (requires login)
// ─────────────────────────────────────────────────────────────
router.post('/users/register-phone', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const { phone } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone required' });

    const normalized = phone.startsWith('+') ? phone : `+91${phone}`;

    await prisma.user.update({
      where: { id: userId },
      data: { phone: normalized },
    });

    return res.json({ success: true, message: 'Phone registered' });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(400).json({ success: false, message: 'Phone already registered to another account' });
    }
    console.error('[POST /users/register-phone]', err.code || err.name);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;