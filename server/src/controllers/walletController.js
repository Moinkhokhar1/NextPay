const prisma = require("../config/db");

const getWallet = async (req, res) => {
  try {
    const wallet = await prisma.wallet.findUnique({ where: { user_id: req.user.id } });

    res.status(200).json(wallet);
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server Error" });
  }
};

const getTransactions = async (req, res) => {
  try {
    console.log("CURRENT USER:", req.user);

    const transactions = await prisma.transaction.findMany({
      where: {
        OR: [
          { sender_id: req.user.id },
          { receiver_id: req.user.id },
        ],
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        receiver: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
      orderBy: { created_at: "desc" },
    });

    console.log("TX COUNT:", transactions.length);
    console.log("TX DATA:", transactions);

    const safeTransactions = transactions.map((tx) => ({
      ...tx,
      nonce: tx.nonce.toString(),
      senderName: tx.sender?.name,
      receiverName: tx.receiver?.name,
    }));

    res.status(200).json(safeTransactions);
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server Error" });
  }
};

const transferMoney = async (req, res) => {
  try {
    const { receiverId, amount, note } = req.body;
    const senderId = req.user.id;

    const senderWallet = await prisma.wallet.findUnique({ where: { user_id: senderId } });

    if (!senderWallet || senderWallet.balance < Number(amount)) {
      return res.status(400).json({ success: false, message: "Insufficient balance" });
    }

    const receiverWallet = await prisma.wallet.findUnique({
      where: { user_id: receiverId },
      include: { user: true },
    });

    if (!receiverWallet) {
      return res.status(404).json({ success: false, message: "Receiver not found" });
    }

    const result = await prisma.$transaction([
      prisma.wallet.update({
        where: { user_id: senderId },
        data: { balance: { decrement: parseFloat(Number(amount).toFixed(2)) } },
      }),
      prisma.wallet.update({
        where: { user_id: receiverId },
        data: { balance: { increment: parseFloat(Number(amount).toFixed(2)) } },
      }),
      prisma.transaction.create({
        data: {
          sender_id: senderId,
          receiver_id: receiverId,
          amount: Number(amount),
          status: "completed",
          nonce: BigInt(Date.now()),
          signature: "online-transfer",
          note: note?.trim() || null,
          is_offline: false,
        },
      }),
    ]);

    const createdTransaction = result[2]; // 👈 the transaction.create result

    return res.json({
      success: true,
      receiverName: receiverWallet.user.name,
      transactionId: createdTransaction.id,       // 👈 new
      createdAt: createdTransaction.created_at,
    });
  } catch (error) {
    console.log("TRANSFER ERROR:", error);

    res.status(500).json({
      success: false,
      message: "Transfer failed",
      error: error.message
    });
  }
};

const getLatestIncoming = async (req, res) => {
  try {
    const userId = req.user.id; // from authMiddleware
    const { after } = req.query;

    const transactions = await prisma.transaction.findMany({
      where: {
        receiver_id: userId,
        status: "completed",
        ...(after ? { created_at: { gt: new Date(after) } } : {}),
      },
      orderBy: { created_at: "desc" },
      take: 10,
      include: {
        sender: { select: { name: true } },
      },
    });

    res.json({
      transactions: transactions.map(tx => ({
        id: tx.id,
        amount: tx.amount,
        senderName: tx.sender?.name || null,
        createdAt: tx.created_at.toISOString(),
      })),
    });
  } catch (err) {
    console.error("latest-incoming error:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getWallet, getTransactions, transferMoney, getLatestIncoming };

// module.exports = { getWallet, getTransactions, transferMoney };