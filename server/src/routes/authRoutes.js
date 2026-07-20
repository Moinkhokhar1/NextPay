const express = require("express");
const prisma = require("../config/db");
const router = express.Router();

const {
  registerUser,
  loginUser,
  getProfile,
  sendLoginOtp,
  verifyLoginOtp,
} = require("../controllers/authController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/send-otp", sendLoginOtp);
router.post("/verify-otp", verifyLoginOtp);
router.get("/profile", authMiddleware, getProfile);
router.get("/users/by-phone/:phone", authMiddleware, async (req, res) => {
  try {
    let phone = req.params.phone.trim();

    // If user enters without +91, add it
    if (!phone.startsWith("+91")) {
      phone = `+91${phone}`;
    }

    const user = await prisma.user.findUnique({
      where: { phone },
      select: {
        id: true,
        name: true,
        phone: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    res.status(200).json(user);
  } catch (error) {
    console.log("FIND USER ERROR:", error);
    res.status(500).json({
      message: "Server Error",
    });
  }
});

module.exports = router;