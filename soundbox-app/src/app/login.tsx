import { useState } from "react";
import {
    View,
    Text,
    TextInput,
    TouchableOpacity,
    StyleSheet,
    Alert,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useRouter } from "expo-router";
import { API_BASE_URL, MERCHANT_TOKEN_KEY } from "../constants/config";

export default function Login() {
    const [identifier, setIdentifier] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleLogin = async () => {
        if (!identifier || !password) return Alert.alert("Error", "Fill all fields");
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE_URL}/auth/login`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email: identifier, password }),
            });
            const data = await res.json();
            if (!res.ok) throw new Error(data.message || "Login failed");

            await AsyncStorage.setItem(MERCHANT_TOKEN_KEY, data.token);
            router.replace("/soundbox" as any);
        } catch (e: any) {
            Alert.alert("Login Failed", e.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <View style={styles.root}>
            <Text style={styles.title}>SOUNDBOX</Text>
            <Text style={styles.sub}>Sign in with your OfflinePay account</Text>

            <TextInput
                style={styles.input}
                placeholder="Username / Email / Phone"
                placeholderTextColor="#9A7A5A"
                value={identifier}
                onChangeText={setIdentifier}
                autoCapitalize="none"
            />
            <TextInput
                style={styles.input}
                placeholder="Password"
                placeholderTextColor="#9A7A5A"
                value={password}
                onChangeText={setPassword}
                secureTextEntry
            />

            <TouchableOpacity
                style={styles.btn}
                onPress={handleLogin}
                disabled={loading}
            >
                <Text style={styles.btnText}>
                    {loading ? "SIGNING IN..." : "SIGN IN →"}
                </Text>
            </TouchableOpacity>
        </View>
    );
}

const styles = StyleSheet.create({
    root: {
        flex: 1,
        backgroundColor: "#1A0A00",
        justifyContent: "center",
        paddingHorizontal: 24,
    },
    title: {
        color: "#F3EBDD",
        fontSize: 28,
        fontWeight: "900",
        letterSpacing: 6,
        textAlign: "center",
        marginBottom: 8,
    },
    sub: {
        color: "#9A7A5A",
        fontSize: 12,
        textAlign: "center",
        marginBottom: 40,
        letterSpacing: 1,
    },
    input: {
        backgroundColor: "#231208",
        borderWidth: 2,
        borderColor: "#3A2A1A",
        color: "#F3EBDD",
        padding: 14,
        marginBottom: 14,
        fontSize: 14,
    },
    btn: {
        backgroundColor: "#C85A1E",
        padding: 16,
        alignItems: "center",
        marginTop: 8,
    },
    btnText: {
        color: "#F3EBDD",
        fontWeight: "900",
        fontSize: 14,
        letterSpacing: 3,
    },
});