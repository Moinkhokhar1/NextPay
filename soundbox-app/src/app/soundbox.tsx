import { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Platform,
  AppState,
  AppStateStatus,
  Switch,
  Animated,
  Easing,
  TouchableOpacity,
} from "react-native";
import { useRouter } from "expo-router";
import * as Speech from "expo-speech";
import * as Haptics from "expo-haptics";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { API_BASE_URL, POLL_INTERVAL_MS, MERCHANT_TOKEN_KEY } from "../constants/config";

const LAST_TX_KEY = "soundbox_last_tx_id";

interface LogEntry {
  id: string | number;
  amount: number;
  sender: string;
  time: string;
}

interface Transaction {
  id: string;
  amount: number;
  senderName: string | null;
  createdAt: string;
}

// ─── Pulse Ring ───────────────────────────────────────────────────────────────
function PulseRing({ active }: { active: boolean }) {
  const ring1 = useRef(new Animated.Value(0)).current;
  const ring2 = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!active) {
      ring1.setValue(0);
      ring2.setValue(0);
      return;
    }
    const pulse = (anim: Animated.Value, delay: number) =>
      Animated.loop(
        Animated.sequence([
          Animated.delay(delay),
          Animated.timing(anim, {
            toValue: 1,
            duration: 1400,
            easing: Easing.out(Easing.ease),
            useNativeDriver: true,
          }),
          Animated.timing(anim, { toValue: 0, duration: 0, useNativeDriver: true }),
        ])
      );
    pulse(ring1, 0).start();
    pulse(ring2, 700).start();
    return () => {
      ring1.stopAnimation();
      ring2.stopAnimation();
    };
  }, [active]);

  return (
    <>
      {[ring1, ring2].map((r, i) => (
        <Animated.View
          key={i}
          style={[
            styles.pulseRing,
            {
              opacity: r.interpolate({ inputRange: [0, 0.3, 1], outputRange: [0, 0.35, 0] }),
              transform: [{ scale: r.interpolate({ inputRange: [0, 1], outputRange: [0.8, 2.4] }) }],
            },
          ]}
        />
      ))}
    </>
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
export default function SoundBox() {
  const [active, setActive] = useState(true);
  const [lastTx, setLastTx] = useState<LogEntry | null>(null);
  const [status, setStatus] = useState("Listening...");
  const [log, setLog] = useState<LogEntry[]>([]);
    const router = useRouter();

  const appState = useRef<AppStateStatus>(AppState.currentState);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const activeRef = useRef(true);

  // keep ref in sync so interval callback always sees current value
 useEffect(() => {
    AsyncStorage.removeItem("soundbox_last_tx_id");
  }, []);

  // ── Announce in Hindi ─────────────────────────────────────────────────
  const announcehindi = (amount: number, senderName: string | null) => {
    const text = senderName
      ? `${senderName} se ${amount} rupaye prapt huye`
      : `${amount} rupaye prapt huye`;
    Speech.speak(text, { language: "hi-IN", pitch: 1.05, rate: 0.92 });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };
  // ── Announce in english ─────────────────────────────────────────────────
  const announceenglish = (amount: number, senderName: string | null) => {
    const text = senderName
      ? `${senderName} has sent you ${amount} rupees`
      : `You have received ${amount} rupees`;
    Speech.speak(text, { language: "en-IN", pitch: 1.05, rate: 0.92 });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };
  // ── Poll backend ──────────────────────────────────────────────────────
  const poll = async () => {
    if (!activeRef.current) return;
    try {
      const token = await AsyncStorage.getItem(MERCHANT_TOKEN_KEY);
      if (!token) { setStatus("No auth token — set in config"); return; }

      const lastTime = await AsyncStorage.getItem(LAST_TX_KEY);
      console.log("LAST TIME SENT:", lastTime);
      const url = `${API_BASE_URL}/wallet/transactions/latest-incoming${lastTime ? `?after=${lastTime}` : ""}`;

      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) { setStatus(`Server error ${res.status}`); return; }

      const data: { transactions: Transaction[] } = await res.json();

      if (data.transactions?.length > 0) {
        for (const tx of [...data.transactions].reverse()) {
          announcehindi(tx.amount, tx.senderName);
          announceenglish(tx.amount, tx.senderName);
          const entry: LogEntry = {
            id: tx.id,
            amount: tx.amount,
            sender: tx.senderName || "Unknown",
            time: new Date().toLocaleTimeString("en-IN"),
          };
          setLog(prev => [entry, ...prev.slice(0, 19)]);
          setLastTx(entry);
        }
        await AsyncStorage.setItem(LAST_TX_KEY, data.transactions[0].createdAt);
      }

      setStatus("Listening...");
    } catch (e) {
      console.log("POLL ERROR:", JSON.stringify(e));  // ← add this line
      setStatus("Network error — retrying...");
    }
  };

  // ── Start / stop polling ──────────────────────────────────────────────
  useEffect(() => {
    if (active) {
      poll();
      pollRef.current = setInterval(poll, POLL_INTERVAL_MS);
    } else {
      if (pollRef.current) clearInterval(pollRef.current);
      setStatus("Paused");
    }
    return () => {
      if (pollRef.current) clearInterval(pollRef.current);
    };
  }, [active]);

  // ── Catch up when app foregrounded ────────────────────────────────────
  useEffect(() => {
    const sub = AppState.addEventListener("change", (next) => {
      if (next === "active" && appState.current !== "active" && activeRef.current) poll();
      appState.current = next;
    });
    return () => sub.remove();
  }, []);

  return (
    <View style={styles.root}>
      {/* TOP BAR */}
<View style={styles.topBar}>
    <Text style={styles.appName}>SOUNDBOX</Text>
    <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
        <View style={[styles.dot, { backgroundColor: active ? "#1E6B37" : "#9A7A5A" }]} />
        <TouchableOpacity onPress={async () => {
            await AsyncStorage.removeItem(MERCHANT_TOKEN_KEY);
            router.replace("/login" as any);
        }}>
            <Text style={{ color: "#9A7A5A", fontSize: 11, fontWeight: "700", letterSpacing: 1 }}>
                LOGOUT
            </Text>
        </TouchableOpacity>
    </View>
</View>

      {/* MIC ZONE */}
      <View style={styles.micZone}>
        <PulseRing active={active} />
        <View style={[styles.micCircle, !active && styles.micCircleOff]}>
          <Text style={styles.micIcon}>🎙</Text>
        </View>
        <Text style={styles.statusText}>{status}</Text>
      </View>

      {/* LAST PAYMENT CARD */}
      <View style={styles.lastCard}>
        <Text style={styles.lastLabel}>LAST RECEIVED</Text>
        <Text style={styles.lastAmount}>{lastTx ? `₹${lastTx.amount}` : "—"}</Text>
        <Text style={styles.lastSender}>{lastTx?.sender ?? "—"}</Text>
      </View>

      {/* TOGGLE */}
      <View style={styles.toggleRow}>
        <Text style={styles.toggleLabel}>{active ? "ACTIVE" : "PAUSED"}</Text>
        <Switch
          value={active}
          onValueChange={setActive}
          trackColor={{ false: "#C4B49A", true: "#1E6B37" }}
          thumbColor="#F3EBDD"
        />
      </View>

      {/* RECENT LOG */}
      {log.length > 0 && (
        <View style={styles.logBox}>
          <Text style={styles.logHeader}>RECENT</Text>
          {log.slice(0, 5).map((entry, i) => (
            <View key={String(entry.id) + i} style={styles.logRow}>
              <Text style={styles.logSender}>{entry.sender}</Text>
              <Text style={styles.logAmount}>₹{entry.amount}</Text>
              <Text style={styles.logTime}>{entry.time}</Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#1A0A00",
    paddingTop: Platform.OS === "android" ? 40 : 58,
    paddingHorizontal: 20,
  },
  topBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 32,
  },
  appName: { color: "#F3EBDD", fontSize: 13, fontWeight: "900", letterSpacing: 4 },
  dot: { width: 10, height: 10, borderRadius: 5 },

  micZone: { alignItems: "center", justifyContent: "center", marginBottom: 36, height: 200 },
  pulseRing: {
    position: "absolute",
    width: 130, height: 130, borderRadius: 65,
    borderWidth: 3, borderColor: "#1E6B37",
  },
  micCircle: {
    width: 110, height: 110, borderRadius: 55,
    backgroundColor: "#1E6B37",
    borderWidth: 3, borderColor: "#F3EBDD",
    justifyContent: "center", alignItems: "center",
    shadowColor: "#1E6B37",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8, shadowRadius: 20, elevation: 10,
  },
  micCircleOff: { backgroundColor: "#3A2A1A", borderColor: "#9A7A5A", shadowOpacity: 0 },
  micIcon: { fontSize: 44 },
  statusText: { marginTop: 18, color: "#9A7A5A", fontSize: 11, fontWeight: "700", letterSpacing: 2 },

  lastCard: {
    backgroundColor: "#231208",
    borderWidth: 2, borderColor: "#C85A1E", borderLeftWidth: 5,
    padding: 18, marginBottom: 16,
  },
  lastLabel: { color: "#9A7A5A", fontSize: 10, fontWeight: "900", letterSpacing: 2.5, marginBottom: 4 },
  lastAmount: { color: "#F3EBDD", fontSize: 36, fontWeight: "900", letterSpacing: 1 },
  lastSender: { color: "#C85A1E", fontSize: 13, fontWeight: "700", marginTop: 2 },

  toggleRow: {
    flexDirection: "row", justifyContent: "space-between", alignItems: "center",
    backgroundColor: "#231208",
    borderWidth: 2, borderColor: "#3A2A1A",
    padding: 16, marginBottom: 20,
  },
  toggleLabel: { color: "#F3EBDD", fontSize: 12, fontWeight: "900", letterSpacing: 3 },

  logBox: { backgroundColor: "#231208", borderWidth: 2, borderColor: "#3A2A1A", padding: 14 },
  logHeader: { color: "#9A7A5A", fontSize: 10, fontWeight: "900", letterSpacing: 2.5, marginBottom: 10 },
  logRow: {
    flexDirection: "row", justifyContent: "space-between",
    paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: "#2E1A08",
  },
  logSender: { color: "#F3EBDD", fontSize: 12, fontWeight: "600", flex: 1 },
  logAmount: { color: "#1E6B37", fontSize: 12, fontWeight: "900", marginHorizontal: 8 },
  logTime: { color: "#9A7A5A", fontSize: 11 },
});