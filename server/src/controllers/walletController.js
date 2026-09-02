// const { Prisma } = require("@prisma/client");
// const prisma = require("../config/db");

// const getWallet = async (req, res) => {
//   try {
//     const wallet = await prisma.wallet.findUnique({
//       where: { user_id: req.user.id },
//     });

//     res.status(200).json(wallet);
//   } catch (error) {
//     console.error(error);
//     res.status(500).json({ message: "Server Error" });
//   }
// };

// const getTransactions = async (req, res) => {
//   try {
//     const transactions = await prisma.transaction.findMany({
//       where: {
//         OR: [
//           { sender_id: req.user.id },
//           { receiver_id: req.user.id },
//         ],
//       },
//       include: {
//         sender: {
//           select: {
//             id: true,
//             name: true,
//             phone: true,
//           },
//         },
//         receiver: {
//           select: {
//             id: true,
//             name: true,
//             phone: true,
//           },
//         },
//       },
//       orderBy: {
//         created_at: "desc",
//       },
//     });

//     const safeTransactions = transactions.map((tx) => ({
//       ...tx,
//       nonce: tx.nonce.toString(),
//       senderName: tx.sender?.name || null,
//       receiverName: tx.receiver?.name || null,
//     }));

//     res.status(200).json(safeTransactions);
//   } catch (error) {
//     console.error(error);
//     res.status(500).json({ message: "Server Error" });
//   }
// };

// const transferMoney = async (req, res) => {
//   try {
//     const { receiverId, amount: rawAmount, note } = req.body;
//     const senderId = req.user.id;

//     if (!receiverId || typeof receiverId !== "string") {
//       return res.status(400).json({
//         success: false,
//         message: "receiverId is required",
//       });
//     }

//     if (receiverId === senderId) {
//       return res.status(400).json({
//         success: false,
//         message: "Cannot transfer to yourself",
//       });
//     }

//     let amount;

//     try {
//       amount = new Prisma.Decimal(rawAmount).toDecimalPlaces(2);
//     } catch {
//       return res.status(400).json({
//         success: false,
//         message: "Invalid amount",
//       });
//     }

//     if (!amount.isFinite() || amount.lte(0)) {
//       return res.status(400).json({
//         success: false,
//         message: "Amount must be positive",
//       });
//     }

//     const receiverWallet = await prisma.wallet.findUnique({
//       where: {
//         user_id: receiverId,
//       },
//       include: {
//         user: true,
//       },
//     });

//     if (!receiverWallet) {
//       return res.status(404).json({
//         success: false,
//         message: "Receiver not found",
//       });
//     }

//     let createdTransaction;

//     try {
//       createdTransaction = await prisma.$transaction(async (tx) => {
//         const debit = await tx.wallet.updateMany({
//           where: {
//             user_id: senderId,
//             balance: {
//               gte: amount,
//             },
//           },
//           data: {
//             balance: {
//               decrement: amount,
//             },
//           },
//         });

//         if (debit.count === 0) {
//           throw new Error("INSUFFICIENT_FUNDS");
//         }

//         await tx.wallet.update({
//           where: {
//             user_id: receiverId,
//           },
//           data: {
//             balance: {
//               increment: amount,
//             },
//           },
//         });

//         return tx.transaction.create({
//           data: {
//             sender_id: senderId,
//             receiver_id: receiverId,
//             amount,
//             status: "completed",
//             nonce:
//               BigInt(Date.now()) * 1000n +
//               BigInt(Math.floor(Math.random() * 1000)),
//             signature: "online-transfer",
//             note: note?.trim() || null,
//             is_offline: false,
//           },
//         });
//       });
//     } catch (err) {
//       if (err.message === "INSUFFICIENT_FUNDS") {
//         return res.status(400).json({
//           success: false,
//           message: "Insufficient balance",
//         });
//       }

//       throw err;
//     }

//     res.json({
//       success: true,
//       receiverName: receiverWallet.user.name,
//       transactionId: createdTransaction.id,
//       createdAt: createdTransaction.created_at,
//     });
//   } catch (error) {
//     console.error("TRANSFER ERROR:", error);

//     res.status(500).json({
//       success: false,
//       message: "Transfer failed",
//     });
//   }
// };

// const getLatestIncoming = async (req, res) => {
//   try {
//     const userId = req.user.id;
//     const { after } = req.query;

//     const transactions = await prisma.transaction.findMany({
//       where: {
//         receiver_id: userId,
//         status: "completed",
//         ...(after
//           ? {
//               created_at: {
//                 gt: new Date(after),
//               },
//             }
//           : {}),
//       },
//       orderBy: {
//         created_at: "desc",
//       },
//       take: 10,
//       include: {
//         sender: {
//           select: {
//             name: true,
//           },
//         },
//       },
//     });

//     res.json({
//       transactions: transactions.map((tx) => ({
//         id: tx.id,
//         amount: tx.amount,
//         senderName: tx.sender?.name || null,
//         createdAt: tx.created_at.toISOString(),
//       })),
//     });
//   } catch (error) {
//     console.error(error);

//     res.status(500).json({
//       error: "Server error",
//     });
//   }
// };

// module.exports = {
//   getWallet,
//   getTransactions,
//   transferMoney,
//   getLatestIncoming,
// };
const { Prisma } = require("@prisma/client");
const prisma = require("../config/db");

const getWallet = async (req, res) => {
  try {
    const wallet = await prisma.wallet.findUnique({
      where: { user_id: req.user.id },
    });

    res.status(200).json(wallet);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
};

const getTransactions = async (req, res) => {
  try {
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
      orderBy: {
        created_at: "desc",
      },
    });

    const safeTransactions = transactions.map((tx) => ({
      ...tx,
      nonce: tx.nonce.toString(),
      senderName: tx.sender?.name || null,
      receiverName: tx.receiver?.name || null,
    }));

    res.status(200).json(safeTransactions);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
};

const transferMoney = async (req, res) => {
  try {
    const { receiverId, amount: rawAmount, note } = req.body;
    const senderId = req.user.id;

    if (!receiverId || typeof receiverId !== "string") {
      return res.status(400).json({
        success: false,
        message: "receiverId is required",
      });
    }

    if (receiverId === senderId) {
      return res.status(400).json({
        success: false,
        message: "Cannot transfer to yourself",
      });
    }

    let amount;

    try {
      amount = new Prisma.Decimal(rawAmount).toDecimalPlaces(2);
    } catch {
      return res.status(400).json({
        success: false,
        message: "Invalid amount",
      });
    }

    if (!amount.isFinite() || amount.lte(0)) {
      return res.status(400).json({
        success: false,
        message: "Amount must be positive",
      });
    }

    const receiverWallet = await prisma.wallet.findUnique({
      where: {
        user_id: receiverId,
      },
      include: {
        user: true,
      },
    });

    if (!receiverWallet) {
      return res.status(404).json({
        success: false,
        message: "Receiver not found",
      });
    }

    let createdTransaction;

    try {
      createdTransaction = await prisma.$transaction(async (tx) => {
        const debit = await tx.wallet.updateMany({
          where: {
            user_id: senderId,
            balance: {
              gte: amount,
            },
          },
          data: {
            balance: {
              decrement: amount,
            },
          },
        });

        if (debit.count === 0) {
          throw new Error("INSUFFICIENT_FUNDS");
        }

        await tx.wallet.update({
          where: {
            user_id: receiverId,
          },
          data: {
            balance: {
              increment: amount,
            },
          },
        });

        return tx.transaction.create({
          data: {
            sender_id: senderId,
            receiver_id: receiverId,
            amount,
            status: "completed",
            nonce:
              BigInt(Date.now()) * 1000n +
              BigInt(Math.floor(Math.random() * 1000)),
            signature: "online-transfer",
            note: note?.trim() || null,
            is_offline: false,
          },
        });
      });
    } catch (err) {
      if (err.message === "INSUFFICIENT_FUNDS") {
        return res.status(400).json({
          success: false,
          message: "Insufficient balance",
        });
      }

      throw err;
    }

    res.json({
      success: true,
      receiverName: receiverWallet.user.name,
      transactionId: createdTransaction.id,
      createdAt: createdTransaction.created_at,
    });
  } catch (error) {
    console.error("TRANSFER ERROR:", error);

    res.status(500).json({
      success: false,
      message: "Transfer failed",
    });
  }
};

const getLatestIncoming = async (req, res) => {
  try {
    const userId = req.user.id;
    const { after } = req.query;

    const transactions = await prisma.transaction.findMany({
      where: {
        receiver_id: userId,
        status: "completed",
        ...(after
          ? {
              created_at: {
                gt: new Date(after),
              },
            }
          : {}),
      },
      orderBy: {
        created_at: "desc",
      },
      take: 10,
      include: {
        sender: {
          select: {
            name: true,
          },
        },
      },
    });

    res.json({
      transactions: transactions.map((tx) => ({
        id: tx.id,
        amount: tx.amount,
        senderName: tx.sender?.name || null,
        createdAt: tx.created_at.toISOString(),
      })),
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Server error",
    });
  }
};

/// Moves real money from the user's main balance into their offline
/// spending pool. This happens ONLINE, server-side, atomically — by the
/// time the app goes offline, the server has already debited the main
/// balance. That's what makes offline spending's worst-case loss bounded
/// and never a platform accounting error: `balance` is correct the
/// instant this completes, regardless of what happens to the device
/// afterward (lost, uninstalled, never synced).
const rechargeOfflineWallet = async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount: rawAmount } = req.body;

    let amount;
    try {
      amount = new Prisma.Decimal(rawAmount).toDecimalPlaces(2);
    } catch {
      return res.status(400).json({ success: false, message: "Invalid amount" });
    }

    if (!amount.isFinite() || amount.lte(0)) {
      return res.status(400).json({
        success: false,
        message: "Amount must be positive",
      });
    }

    let updatedWallet;

    try {
      updatedWallet = await prisma.$transaction(async (tx) => {
        // Atomic + conditional: only succeeds if balance actually covers
        // it, same pattern as transferMoney — prevents a race between
        // two concurrent recharge requests over-debiting the balance.
        const debit = await tx.wallet.updateMany({
          where: { user_id: userId, balance: { gte: amount } },
          data: { balance: { decrement: amount } },
        });

        if (debit.count === 0) {
          throw new Error("INSUFFICIENT_FUNDS");
        }

        const wallet = await tx.wallet.update({
          where: { user_id: userId },
          data: { offline_balance: { increment: amount } },
        });

        // Audit trail — a self-transfer record so recharge shows up in
        // transaction history same as any other movement of funds.
        await tx.transaction.create({
          data: {
            sender_id: userId,
            receiver_id: userId,
            amount,
            status: "completed",
            nonce:
              BigInt(Date.now()) * 1000n +
              BigInt(Math.floor(Math.random() * 1000)),
            signature: "offline-wallet-recharge",
            note: "Offline wallet recharge",
            is_offline: false,
          },
        });

        return wallet;
      });
    } catch (err) {
      if (err.message === "INSUFFICIENT_FUNDS") {
        return res.status(400).json({
          success: false,
          message: "Insufficient balance",
        });
      }
      throw err;
    }

    res.json({
      success: true,
      wallet: updatedWallet,
    });
  } catch (error) {
    console.error("OFFLINE RECHARGE ERROR:", error);
    res.status(500).json({
      success: false,
      message: "Recharge failed",
    });
  }
};

module.exports = {
  getWallet,
  getTransactions,
  transferMoney,
  getLatestIncoming,
  rechargeOfflineWallet,
};