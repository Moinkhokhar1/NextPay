const express = require("express");

const router = express.Router();

const authMiddleware =
  require("../middleware/authMiddleware");

const {
  syncTransactions,
} = require("../controllers/syncController");

router.post(
  "/transactions",
  authMiddleware,
  syncTransactions
);

module.exports = router;