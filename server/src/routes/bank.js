const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const authMiddleware = require('../middleware/authMiddleware');

// ── GET /api/bank-account ────────────────────────────────────────────────────
router.get('/bank-account', authMiddleware, async (req, res) => {
  try {
    const account = await prisma.bankAccount.findUnique({
      where: { user_id: req.user.id },
    });

    if (!account) {
      return res.status(404).json({ detail: 'No bank account linked' });
    }

    return res.json({
      account_number:       account.accountNumber,
      ifsc_code:            account.ifscCode,
      account_holder_name:  account.accountHolderName,
      created_at:           account.createdAt,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ detail: 'Server error' });
  }
});

// ── POST /api/bank-account ───────────────────────────────────────────────────
router.post('/bank-account', authMiddleware, async (req, res) => {
  const { account_number, ifsc_code, account_holder_name } = req.body;

  if (!account_number || !ifsc_code || !account_holder_name) {
    return res.status(400).json({ detail: 'All fields are required' });
  }

  // Validate IFSC format
  const ifscRegex = /^[A-Z]{4}0[A-Z0-9]{6}$/;
  if (!ifscRegex.test(ifsc_code.toUpperCase())) {
    return res.status(400).json({ detail: 'Invalid IFSC code' });
  }

  // Validate account number length
  if (account_number.length < 9 || account_number.length > 18) {
    return res.status(400).json({ detail: 'Invalid account number' });
  }

  try {
    const account = await prisma.bankAccount.upsert({
      where:  { user_id: req.user.id },
      update: {
        accountNumber:     account_number,
        ifscCode:          ifsc_code.toUpperCase(),
        accountHolderName: account_holder_name,
      },
      create: {
        user_id:            req.user.id,
        accountNumber:     account_number,
        ifscCode:          ifsc_code.toUpperCase(),
        accountHolderName: account_holder_name,
      },
    });

    return res.json({ message: 'Bank account saved', id: account.id });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ detail: 'Server error' });
  }
});

// ── DELETE /api/bank-account ─────────────────────────────────────────────────
router.delete('/bank-account', authMiddleware, async (req, res) => {
  try {
    await prisma.bankAccount.delete({
      where: { user_id: req.user.id },
    });
    return res.json({ message: 'Bank account removed' });
  } catch (err) {
    // P2025 = record not found
    if (err.code === 'P2025') {
      return res.status(404).json({ detail: 'No bank account found' });
    }
    return res.status(500).json({ detail: 'Server error' });
  }
});

// ── POST /api/withdraw ───────────────────────────────────────────────────────
router.post('/withdraw', authMiddleware, async (req, res) => {
  const { amount } = req.body;

  if (!amount || typeof amount !== 'number') {
    return res.status(400).json({ detail: 'Invalid amount' });
  }
  if (amount < 10) {
    return res.status(400).json({ detail: 'Minimum withdrawal is ₹10' });
  }

  try {
    // Get wallet
    const wallet = await prisma.wallet.findUnique({
      where: { user_id: req.user.id },
    });

    if (!wallet) {
      return res.status(404).json({ detail: 'Wallet not found' });
    }

    const available = wallet.balance - (wallet.locked_balance ?? 0);

    if (amount > available) {
      return res.status(400).json({ detail: `Insufficient balance. Available: ₹${available.toFixed(2)}` });
    }

    // Check bank account exists
    const bankAccount = await prisma.bankAccount.findUnique({
      where: { user_id: req.user.id },
    });

    if (!bankAccount) {
      return res.status(400).json({ detail: 'No bank account linked' });
    }

    // Atomic: debit wallet + create withdrawal in one transaction
    const [updatedWallet, withdrawal] = await prisma.$transaction([
      prisma.wallet.update({
        where: { user_id: req.user.id },
        data:  { balance: { decrement: amount } },
      }),
      prisma.withdrawal.create({
        data: {
          user_id: req.user.id,
          amount: amount,
          status: 'pending',
        },
      }),
    ]);

    // TODO: Trigger Razorpay Payout API here in production
    // const payout = await razorpay.payouts.create({ ... })
    // await prisma.withdrawal.update({ where: { id: withdrawal.id }, data: { status: 'processing' } })

    return res.json({
      withdrawal_id: withdrawal.id,
      status:        withdrawal.status,
      amount:        withdrawal.amount,
      new_balance:   updatedWallet.balance,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ detail: 'Server error' });
  }
});

// ── GET /api/withdrawals ─────────────────────────────────────────────────────
router.get('/withdrawals', authMiddleware, async (req, res) => {
  try {
    const withdrawals = await prisma.withdrawal.findMany({
      where:   { user_id: req.user.id },
      orderBy: { createdAt: 'desc' },
      take:    20,
    });

    return res.json(withdrawals.map(w => ({
      id:           w.id,
      amount:       w.amount,
      status:       w.status,
      created_at:   w.createdAt,
      processed_at: w.processedAt,
    })));
  } catch (err) {
    return res.status(500).json({ detail: 'Server error' });
  }
});

module.exports = router;