require("dotenv").config();
const express = require("express");
const cors = require("cors");

const walletRoutes = require("./routes/walletRoutes");

const authRoutes = require("./routes/authRoutes");

const syncRoutes = require("./routes/syncRoutes");

const bankRouter = require('./routes/bank');
const smsRoutes = require('./routes/sms_routes');
 
const app = express();

app.use(cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
}));
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Offline Payment Backend Running");
});

app.use("/api/auth", authRoutes);
app.use("/api/wallet", walletRoutes);
app.use("/api/sync", syncRoutes);
app.use('/api', bankRouter);
app.use('/api', smsRoutes);

const PORT = process.env.PORT || 8000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
