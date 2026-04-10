import fs from "fs";
import admin from "firebase-admin";

const env = String(process.argv[2] || "dev").toLowerCase();
const serviceAccountPath = env === "prod"
    ? `${process.env.HOME}/firebase_accounts/budget-service-account.json`
    : `${process.env.HOME}/firebase_accounts/budget-dev-service-account.json`;

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8")) as admin.ServiceAccount;

const createdSince = new Date(Date.now() - 20 * 24 * 60 * 60 * 1000)
    .toISOString();
const url = `https://api.lunchmoney.dev/v2/transactions?created_since=${encodeURIComponent(createdSince)}&limit=200`;

type LunchMoneyTransaction = {
    id: string;
    [key: string]: unknown;
};

async function fetchTransactions(): Promise<LunchMoneyTransaction[]> {
    const response = await fetch(url, {
        headers: {
            Accept: "application/json",
            Authorization: "Bearer 5c41a19e5331cee0d59d1a58d723fd49c2cebccc0d58f40c54",
        },
    });

    if (!response.ok) {
        throw new Error(`Request failed: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    if (!data?.transactions || !Array.isArray(data.transactions)) {
        throw new Error("Unexpected API response: missing transactions array");
    }

    return data.transactions as LunchMoneyTransaction[];
}

async function main() {
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
    }

    const db = admin.firestore();
    const transactions = await fetchTransactions();
    console.log(`Fetched ${transactions.length} transactions.`);

    const collectionRef = db.collection("users").doc("test").collection("uncategorized");
    let addedCount = 0;
    let skippedCount = 0;

    for (const transaction of transactions) {
        const id = String(transaction.id || "").trim();
        if (!id) {
            console.warn("Skipping transaction without an ID:", transaction);
            continue;
        }

        const docRef = collectionRef.doc(id);
        const snapshot = await docRef.get();
        if (snapshot.exists) {
            skippedCount++;
            continue;
        }

        await docRef.set(transaction);
        addedCount++;
    }

    console.log(`Import complete. added=${addedCount}, skipped=${skippedCount}`);
    process.exit(0);
}

main().catch((err) => {
    console.error("Failed to import transactions:", err);
    process.exit(1);
});
