const prisma = require("../config/db");
const CryptoJS = require("crypto-js");

const SECRET_KEY = "offline-payment-secret";

const syncTransactions = async (req, res) => {
  try {
    const { transactions } = req.body;
    const results = [];

    for (const tx of transactions) {
      console.log("FULL TX:", JSON.stringify(tx, null, 2));

      // Check duplicate tx
      const existingTx = await prisma.transaction.findUnique({ where: { id: tx.txId } });

      if (existingTx) {
        results.push({ txId: tx.txId, status: "duplicate" });
        continue;
      }

      // Verify signature
      const originalPayload = {
        txId: tx.txId,
        sender: tx.sender,
        receiver: tx.receiver,
        amount: tx.amount,
        timestamp: tx.timestamp,
        nonce: tx.nonce,
        status: tx.status,
        synced: false,
      };
      console.log("JS PAYLOAD:", JSON.stringify(originalPayload));
      console.log("JS SIGNATURE:", CryptoJS.SHA256(JSON.stringify(originalPayload) + SECRET_KEY).toString());
      console.log("RECEIVED SIGNATURE:", tx.signature);
      console.log("JS RAW STRING:", JSON.stringify(originalPayload) + SECRET_KEY);
      const generatedSignature = CryptoJS.SHA256(
        JSON.stringify(originalPayload) + SECRET_KEY
      ).toString();

      if (generatedSignature !== tx.signature) {
        results.push({ txId: tx.txId, status: "invalid_signature" });
        continue;
      }

      // Fetch sender wallet
      if (!tx.sender || !tx.receiver) {
        results.push({ txId: tx.txId, status: "invalid_transaction" });
        continue;
      }

      const senderWallet = await prisma.wallet.findUnique({ where: { user_id: tx.sender } });

      if (senderWallet.balance < tx.amount) {
        results.push({ txId: tx.txId, status: "insufficient_balance" });
        continue;
      }

      // Settlement
      await prisma.$transaction([
        prisma.wallet.update({
          where: { user_id: tx.sender },
          data: {
            balance: { decrement: tx.amount },
            locked_balance: { decrement: Math.min(tx.amount, senderWallet.locked_balance) },
          },
        }),
        prisma.wallet.update({
          where: { user_id: tx.receiver },
          data: {
            balance: { increment: tx.amount },
          },
        }),
        prisma.transaction.create({
          data: {
            id: tx.txId,
            sender_id: tx.sender,
            receiver_id: tx.receiver,
            amount: tx.amount,
            status: "completed",
            nonce: tx.nonce,
            signature: tx.signature,
            is_offline: true,
          },
        }),
      ]);

      results.push({ txId: tx.txId, status: "synced" });
    }

    res.status(200).json({ success: true, results });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Sync failed" });
  }
};

module.exports = { syncTransactions };