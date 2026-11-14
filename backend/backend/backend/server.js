
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || false
}));
app.use(express.json({ limit: "20kb" }));

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    app: "MIFADO COIN",
    symbol: "MFD",
    status: "running"
  });
});

app.use("/api", rateLimit({
  windowMs: 60 * 1000,
  limit: 60,
  standardHeaders: true,
  legacyHeaders: false
}));

app.get("/api/status", (req, res) => {
  res.json({
    ok: true,
    message: "MIFADO COIN API is ready"
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`MIFADO COIN server running on port ${PORT}`);
});
