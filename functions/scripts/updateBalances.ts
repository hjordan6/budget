import fs from "fs";
import admin from "firebase-admin";

const env = String(process.argv[2] || "dev").toLowerCase();
const serviceAccountPath = env === "prod"
    ? `${process.env.HOME}/firebase_accounts/budget-service-account.json`
    : `${process.env.HOME}/firebase_accounts/budget-dev-service-account.json`;

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8")) as admin.ServiceAccount;

if (!admin.apps.length) {
    console.log(`Initializing Firebase Admin SDK with service account from ${serviceAccountPath}`);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

function getNextUpdateDate(interval: "year" | "quarter" | "month" | "week"): Date {
    const now = new Date();
    const nextUpdate = new Date(now);

    switch (interval) {
        case "year":
            nextUpdate.setFullYear(now.getFullYear() + 1);
            break;
        case "quarter":
            nextUpdate.setMonth(now.getMonth() + 3);
            break;
        case "month":
            nextUpdate.setMonth(now.getMonth() + 1);
            break;
        case "week":
            nextUpdate.setDate(now.getDate() + 7);
            break;
        default:
            nextUpdate.setMonth(now.getMonth() + 1);
    }

    return nextUpdate;
}

async function main() {
    console.log("Updating balances locally...");
    const firedb = admin.firestore();

    const usernames = await firedb.collection("usernames").get();
    console.log(`Found ${usernames.size} users.`);
    for (const userName of usernames.docs) {
        const userDoc = await firedb.collection("users").doc(userName.id).get();
        const categories = await userDoc.ref.collection("categories").get();
        for (const categoryDoc of categories.docs) {
            console.log(`Checking category ${categoryDoc.id} (${categoryDoc.get("name")})...`);
            const categoryData = categoryDoc.data();
            const nextUpdate = categoryData.nextUpdate?.toDate?.();
            if (nextUpdate && nextUpdate <= new Date()) {
                console.log(
                    `Updating balance for user ${userName} (${userDoc.id}), category ${categoryDoc.id} (${categoryData.name})`,
                );
                const interval = categoryData.interval || "month";
                const nextUpdateDate = getNextUpdateDate(interval);
                await categoryDoc.ref.update({
                    balance: categoryData.balance + categoryData.budget,
                    nextUpdate: admin.firestore.Timestamp.fromDate(nextUpdateDate),
                });
            }
        }
    }

    console.log("Balance update complete.");
}

main().catch((error) => {
    console.error("Failed to update balances:", error);
    process.exit(1);
});
