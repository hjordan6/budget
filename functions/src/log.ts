import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const logClient = onRequest({ cors: true }, (req, res) => {
    const { level, message, metadata } = req.body;
    logger.log(level || "info", message, {
        ...metadata,
        source: "flutter_web",
    });

    res.status(200).send("ok");
});
