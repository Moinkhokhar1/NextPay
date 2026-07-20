const prisma = require("../config/db");
const { normalizePhone } = require("../utils/phoneUtils");

const OTP_LENGTH = 6;
const OTP_EXPIRY_MINUTES = 10;
const OTP_RESEND_SECONDS = 60;
const MAX_ATTEMPTS = 5;

function generateOtpCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendOtpSms(phone, code) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromNumber = process.env.TWILIO_PHONE_NUMBER;

  if (!accountSid || !authToken || !fromNumber) {
    console.log(`[OTP DEV] Phone: ${phone} | Code: ${code}`);
    return { sent: false, devMode: true };
  }

  const twilio = require("twilio")(accountSid, authToken);

  await twilio.messages.create({
    body: `Your NextPay login code is ${code}. Valid for ${OTP_EXPIRY_MINUTES} minutes.`,
    from: fromNumber,
    to: phone,
  });

  return { sent: true, devMode: false };
}

async function sendOtp(rawPhone) {
  const phone = normalizePhone(rawPhone);

  if (!phone) {
    return { ok: false, status: 400, message: "Invalid phone number" };
  }

  const user = await prisma.user.findUnique({ where: { phone } });

  if (!user) {
    return { ok: false, status: 404, message: "No account found with this phone number" };
  }

  const recentOtp = await prisma.otp.findFirst({
    where: { phone },
    orderBy: { created_at: "desc" },
  });

  if (recentOtp) {
    const secondsSinceLast = (Date.now() - recentOtp.created_at.getTime()) / 1000;
    if (secondsSinceLast < OTP_RESEND_SECONDS) {
      const wait = Math.ceil(OTP_RESEND_SECONDS - secondsSinceLast);
      return {
        ok: false,
        status: 429,
        message: `Please wait ${wait}s before requesting another OTP`,
      };
    }
  }

  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  await prisma.otp.deleteMany({ where: { phone } });
  await prisma.otp.create({
    data: {
      phone,
      code,
      expires_at: expiresAt,
    },
  });

  const smsResult = await sendOtpSms(phone, code);

  const response = {
    ok: true,
    status: 200,
    message: "OTP sent successfully",
    phone,
  };

  if (smsResult.devMode && process.env.NODE_ENV !== "production") {
    response.devOtp = code;
  }

  return response;
}

async function verifyOtp(rawPhone, rawCode) {
  const phone = normalizePhone(rawPhone);
  const code = String(rawCode || "").trim();

  if (!phone) {
    return { ok: false, status: 400, message: "Invalid phone number" };
  }

  if (!/^\d{6}$/.test(code)) {
    return { ok: false, status: 400, message: "Invalid OTP format" };
  }

  const otpRecord = await prisma.otp.findFirst({
    where: { phone },
    orderBy: { created_at: "desc" },
  });

  if (!otpRecord) {
    return { ok: false, status: 400, message: "OTP expired or not found. Request a new one." };
  }

  if (otpRecord.expires_at < new Date()) {
    await prisma.otp.delete({ where: { id: otpRecord.id } });
    return { ok: false, status: 400, message: "OTP expired. Request a new one." };
  }

  if (otpRecord.attempts >= MAX_ATTEMPTS) {
    await prisma.otp.delete({ where: { id: otpRecord.id } });
    return { ok: false, status: 400, message: "Too many attempts. Request a new OTP." };
  }

  if (otpRecord.code !== code) {
    await prisma.otp.update({
      where: { id: otpRecord.id },
      data: { attempts: { increment: 1 } },
    });
    return { ok: false, status: 400, message: "Invalid OTP" };
  }

  await prisma.otp.delete({ where: { id: otpRecord.id } });

  const user = await prisma.user.findUnique({
    where: { phone },
    include: { wallet: true },
  });

  if (!user) {
    return { ok: false, status: 404, message: "User not found" };
  }

  return { ok: true, status: 200, user };
}

module.exports = { sendOtp, verifyOtp, normalizePhone };
