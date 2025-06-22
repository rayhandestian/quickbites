const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Sends a notification to the seller when a new order is created.
 */
exports.onOrderCreated = onDocumentCreated({
    document: "orders/{orderId}",
    region: "asia-southeast2"
}, async (event) => {
    const snap = event.data;
    if (!snap) {
        console.log("No data associated with the event");
        return;
    }
    const orderData = snap.data();
    const sellerId = orderData.sellerId;
    const orderId = event.params.orderId;

    if (!sellerId) {
    console.log("No sellerId found in the order document.");
    return null;
    }

    // Get seller's data to find their FCM token
    const userDoc = await admin.firestore().collection("users").doc(sellerId).get();
    if (!userDoc.exists) {
    console.log(`Seller with ID ${sellerId} not found.`);
    return null;
    }
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
    console.log(`FCM token not found for seller ${sellerId}.`);
    return null;
    }

    // Construct the notification message
    const payload = {
    notification: {
        title: "Pesanan Baru Diterima!",
        body: `Anda telah menerima pesanan baru dengan total Rp${orderData.totalPrice}.`,
    },
    data: {
        orderId: orderId,
        screen: "order_details",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
    },
    token: fcmToken,
    };

    // Send the notification
    try {
    console.log(`Sending notification to token: ${fcmToken}`);
    const response = await admin.messaging().send(payload);
    console.log("Successfully sent message:", response);
    return response;
    } catch (error) {
    console.error("Error sending message:", error);
    return null;
    }
});

/**
 * Sends a notification to the buyer when their order status is updated.
 */
exports.onOrderStatusUpdated = onDocumentUpdated({
    document: "orders/{orderId}",
    region: "asia-southeast2"
}, async (event) => {
    const change = event.data;
    if (!change) {
        console.log("No data associated with the event. Exiting.");
        return;
    }

    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Add robust checks
    if (!newValue || !previousValue) {
        console.log("Missing data 'before' or 'after' the update. Exiting.");
        console.log("newValue exists:", !!newValue);
        console.log("previousValue exists:", !!previousValue);
        return null;
    }

    console.log(`Checking status change. Before: ${previousValue.status}, After: ${newValue.status}`);

    // Check if the order status has changed
    if (newValue.status === previousValue.status) {
        console.log("Order status has not changed. Exiting.");
        return null;
    }

    const buyerId = newValue.buyerId;
    if (!buyerId) {
    console.log("No buyerId found in the order document.");
    return null;
    }

    // Get buyer's data to find their FCM token
    const userDoc = await admin.firestore().collection("users").doc(buyerId).get();
    if (!userDoc.exists) {
    console.log(`Buyer with ID ${buyerId} not found.`);
    return null;
    }
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
    console.log(`FCM token not found for buyer ${buyerId}.`);
    return null;
    }

    // Construct the notification message based on the new status
    let notificationBody = "";
    switch (newValue.status) {
    case "processing":
        notificationBody = "Pesanan Anda sedang dibuat oleh penjual.";
        break;
    case "ready_for_pickup":
        notificationBody = "Pesanan Anda sudah siap untuk diambil!";
        break;
    case "completed":
        notificationBody = "Pesanan Anda telah selesai. Terima kasih!";
        break;
    case "cancelled":
        notificationBody = "Mohon maaf, pesanan Anda telah dibatalkan.";
        break;
    default:
        return null; // Don't send notification for other status changes
    }

    const payload = {
    notification: {
        title: "Update Status Pesanan",
        body: notificationBody,
    },
    data: {
        orderId: event.params.orderId,
        screen: "order_tracker", // Direct to order tracker screen
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
    },
    token: fcmToken,
    };

    // Send the notification
    try {
    console.log(`Sending notification to token: ${fcmToken}`);
    const response = await admin.messaging().send(payload);
    console.log("Successfully sent message:", response);
    return response;
    } catch (error) {
    console.error("Error sending message:", error);
    return null;
    }
}); 