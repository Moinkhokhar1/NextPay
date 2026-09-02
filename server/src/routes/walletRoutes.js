// const express = require("express");

// const router = express.Router();

// const authMiddleware = require("../middleware/authMiddleware");

// const {
//   getWallet,
//   getTransactions,
//   transferMoney,
//   getLatestIncoming,
// } = require(
//   "../controllers/walletController"
// );

// router.get("/", authMiddleware, getWallet);

// router.get(
//   "/transactions",
//   authMiddleware,
//   getTransactions
// );

// router.post(
//   "/transfer",
//   authMiddleware,
//   transferMoney
// );
// router.get(
//   "/transactions/latest-incoming", 
//   authMiddleware, 
//   getLatestIncoming
// );

// module.exports = router;
const express = require("express");

const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");

const {
  getWallet,
  getTransactions,
  transferMoney,
  getLatestIncoming,
  rechargeOfflineWallet,
} = require(
  "../controllers/walletController"
);

router.get("/", authMiddleware, getWallet);

router.get(
  "/transactions",
  authMiddleware,
  getTransactions
);

router.post(
  "/transfer",
  authMiddleware,
  transferMoney
);
router.get(
  "/transactions/latest-incoming", 
  authMiddleware, 
  getLatestIncoming
);

router.post(
  "/offline-wallet/recharge",
  authMiddleware,
  rechargeOfflineWallet
);

module.exports = router;