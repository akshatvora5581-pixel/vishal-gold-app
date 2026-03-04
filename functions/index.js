/**
 * Firebase Cloud Functions for Vishal Gold App
 *
 * Functions:
 * 1. onNewStockPublished  - Fires when a product's status changes to 'published'
 * 2. sendManualNotification - Fires when admin writes to the 'notifications' collection
 */

const { onDocumentWritten, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

// ─── Helper: Build a nice category display name ──────────────────────────────
function formatCategory(category) {
    if (!category) return "Gold Jewelry";
    return category
        .replace(/_/g, " ")
        .split(" ")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ");
}

// ─── Helper: Truncate text ───────────────────────────────────────────────────
function truncate(str, max = 80) {
    if (!str) return "";
    return str.length > max ? str.substring(0, max - 3) + "..." : str;
}

// ─── 1. Automatic New Stock Notification ─────────────────────────────────────
//
// Fires any time a document in the `products` collection is created or updated.
// We only send a notification when the status BECOMES 'published' (not on every edit).
//
exports.onNewStockPublished = onDocumentWritten(
    {
        document: "products/{productId}",
        region: "us-central1",
    },
    async (event) => {
        const before = event.data.before.exists ? event.data.before.data() : null;
        const after = event.data.after.exists ? event.data.after.data() : null;

        // Guard: only fire when status transitions TO 'published'
        const wasPublished = before?.status === "published";
        const isNowPublished = after?.status === "published";

        if (!isNowPublished) {
            console.log("Product status is not 'published'. Skipping notification.");
            return null;
        }

        if (wasPublished) {
            console.log("Product was already published. Skipping notification.");
            return null;
        }

        const productId = event.params.productId;
        const tagNumber = after.tag_number || "";
        const name = after.name || "";
        const category = formatCategory(after.category || "");
        const subcategory = after.subcategory || "";
        const imageUrls = after.image_urls || [];
        const imageUrl = imageUrls.length > 0 ? imageUrls[0] : null;

        // Build a compelling notification body
        const displayName = name
            ? `${name} (${tagNumber})`
            : tagNumber || "New Item";
        const body = truncate(
            `Check out the newly added ${displayName} in ${category}${subcategory ? ` › ${subcategory}` : ""}.`
        );

        const message = {
            topic: "all_users",
            notification: {
                title: "New Stock Alert! 🚀",
                body: body,
                ...(imageUrl && { imageUrl: imageUrl }),
            },
            data: {
                productId: productId,
                type: "new_stock",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                // High priority ensures delivery even in Doze mode
                priority: "high",
                notification: {
                    channelId: "new_stock_channel",
                    ...(imageUrl && { imageUrl: imageUrl }),
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: "New Stock Alert! 🚀",
                            body: body,
                        },
                        badge: 1,
                        sound: "default",
                    },
                },
                fcmOptions: {
                    ...(imageUrl && { imageUrl: imageUrl }),
                },
            },
        };

        try {
            const response = await getMessaging().send(message);
            console.log(`[onNewStockPublished] Notification sent successfully. MessageId: ${response}`);

            // Mark the notification as sent in Firestore (optional audit)
            await getFirestore()
                .collection("notification_logs")
                .add({
                    productId: productId,
                    productTag: tagNumber,
                    title: "New Stock Alert! 🚀",
                    body: body,
                    topic: "all_users",
                    sentAt: new Date(),
                    type: "new_stock",
                    messageId: response,
                });

            return response;
        } catch (error) {
            console.error("[onNewStockPublished] Error sending notification:", error);
            throw error;
        }
    }
);

// ─── 2. Manual Notification (from Admin FCM Console) ─────────────────────────
//
// Fires when the admin writes a doc to the `notifications` collection
// (triggered by AdminFCMConsoleScreen → FirebaseService.sendNotificationRequest)
//
exports.sendManualNotification = onDocumentCreated(
    {
        document: "notifications/{notifId}",
        region: "us-central1",
    },
    async (event) => {
        const data = event.data.data();
        if (!data) {
            console.log("No data found in notification document.");
            return null;
        }

        const { title, body, imageUrl, target, type } = data;

        if (!title || !body) {
            console.log("Missing title or body. Skipping.");
            return null;
        }

        // Determine FCM topic from the `target` field set by the admin console
        const topic =
            target === "wholesalers"
                ? "wholesalers"
                : target === "admin"
                    ? "admin"
                    : "all_users";

        const message = {
            topic: topic,
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl: imageUrl }),
            },
            data: {
                type: type || "manual_push",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "new_stock_channel",
                    ...(imageUrl && { imageUrl: imageUrl }),
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: { title: title, body: body },
                        badge: 1,
                        sound: "default",
                    },
                },
                ...(imageUrl && { fcmOptions: { imageUrl: imageUrl } }),
            },
        };

        try {
            const response = await getMessaging().send(message);
            console.log(`[sendManualNotification] Sent to topic '${topic}'. MessageId: ${response}`);

            // Update the notification doc status
            await event.data.ref.update({
                status: "sent",
                messageId: response,
                sentAt: new Date(),
                sentToTopic: topic,
            });

            return response;
        } catch (error) {
            console.error("[sendManualNotification] Error:", error);
            // Mark as failed so admin can see it in console
            await event.data.ref.update({ status: "failed", error: error.message });
            throw error;
        }
    }
);
