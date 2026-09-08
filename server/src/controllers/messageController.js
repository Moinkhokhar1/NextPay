const prisma = require("../config/db");

// GET /api/messages/:contactId — the chat thread between the logged-in
// user and one contact, oldest first (same ordering the transaction
// history feed uses).
const getMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { contactId } = req.params;

    if (!contactId || typeof contactId !== "string") {
      return res.status(400).json({ message: "contactId is required" });
    }

    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { sender_id: userId, receiver_id: contactId },
          { sender_id: contactId, receiver_id: userId },
        ],
      },
      orderBy: { created_at: "asc" },
    });

    res.status(200).json(messages);
  } catch (error) {
    console.error("GET MESSAGES ERROR:", error);
    res.status(500).json({ message: "Server Error" });
  }
};

// POST /api/messages — send a chat message to a contact.
const sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { receiverId, content } = req.body;

    if (!receiverId || typeof receiverId !== "string") {
      return res.status(400).json({ message: "receiverId is required" });
    }

    const trimmed = typeof content === "string" ? content.trim() : "";
    if (!trimmed) {
      return res.status(400).json({ message: "Message cannot be empty" });
    }

    if (trimmed.length > 1000) {
      return res.status(400).json({ message: "Message is too long" });
    }

    if (receiverId === senderId) {
      return res.status(400).json({ message: "Cannot message yourself" });
    }

    const receiver = await prisma.user.findUnique({
      where: { id: receiverId },
      select: { id: true },
    });

    if (!receiver) {
      return res.status(404).json({ message: "Recipient not found" });
    }

    const message = await prisma.message.create({
      data: {
        sender_id: senderId,
        receiver_id: receiverId,
        content: trimmed,
      },
    });

    res.status(201).json(message);
  } catch (error) {
    console.error("SEND MESSAGE ERROR:", error);
    res.status(500).json({ message: "Server Error" });
  }
};

module.exports = { getMessages, sendMessage };
