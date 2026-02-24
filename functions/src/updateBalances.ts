import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

function getNextUpdateDate(interval: 'year' | 'quarter' | 'month' | 'week'): Date {
    const now = new Date();
    const nextUpdate = new Date(now);

    switch (interval) {
        case 'year':
            nextUpdate.setFullYear(now.getFullYear() + 1);
            break;
        case 'quarter':
            nextUpdate.setMonth(now.getMonth() + 3);
            break;
        case 'month':
            nextUpdate.setMonth(now.getMonth() + 1);
            break;
        case 'week':
            nextUpdate.setDate(now.getDate() + 7);
            break;
        default:
            nextUpdate.setMonth(now.getMonth() + 1); // default to month
    }

    return nextUpdate;
}

export const updateBalances = onSchedule({ schedule: "0 2 * * *", timeZone: "America/Phoenix" }, async () => {
    logger.info("Updating balances...");
    const firedb = admin.firestore();

    const users = await firedb.collection("users").get();

    for (const userDoc of users.docs) {
        const userName = String(userDoc.get("name") ?? userDoc.id);

        const categories = await userDoc.ref.collection("categories").get();
        for (const categoryDoc of categories.docs) {
            if (categoryDoc.data().nextUpdate && categoryDoc.data().nextUpdate.toDate() <= new Date()) {
                logger.info(`Updating balance for user ${userName} (${userDoc.id}), category ${categoryDoc.id} (${categoryDoc.data().name})`);
                const interval = categoryDoc.data().interval || 'month';
                const nextUpdateDate = getNextUpdateDate(interval);
                await categoryDoc.ref.update({
                    balance: categoryDoc.data().balance + categoryDoc.data().budget,
                    nextUpdate: admin.firestore.Timestamp.fromDate(nextUpdateDate),
                });
            }
        }
    }
});
