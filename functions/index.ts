import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Sends a VoIP notification to a target user.
 * 
 * Request body:
 * {
 *   "callerName": "Alice",
 *   "callerId": "user_alice",
 *   "calleeId": "user_bob",
 *   "uuid": "call_uuid_v4", 
 *   "hasVideo": true
 * }
 */
export const makeCall = functions.https.onRequest(async (req, res) => {
  try {
    const { callerName, callerId, calleeId, uuid, hasVideo } = req.body;

    if (!calleeId || !uuid) {
      res.status(400).send("Missing calleeId or uuid");
      return;
    }

    // 1. Fetch callee's tokens from Firestore
    // Assumes structure: /users/{userId} with field `fcmToken` and `voipToken`
    // Or /users/{userId}/tokens/{tokenId}
    // For this example, let's assume a simple field lookup
    const userDoc = await admin.firestore().collection("users").doc(calleeId).get();
    
    if (!userDoc.exists) {
      res.status(404).send("User not found");
      return;
    }

    const userData = userDoc.data();
    const androidToken = userData?.fcmToken; // Normal FCM Token
    const iosVoipToken = userData?.voipToken; // APNs VoIP Token (Not FCM token)

    const promises = [];

    // 2. Android Payload (FCM Data Message)
    if (androidToken) {
      const androidMessage: admin.messaging.Message = {
        token: androidToken,
        data: {
          uuid: uuid,
          name: callerName || "Unknown",
          handle: callerId || "000000",
          type: hasVideo ? "1" : "0", // 0: Audio, 1: Video
          userId: callerId,
          // Custom fields for your app
          callType: "voip_incoming",
        },
        android: {
          priority: "high",
          ttl: 0, // Deliver immediately or fail
        },
      };
      
      console.log(`Sending Android VoIP to ${calleeId}`);
      promises.push(admin.messaging().send(androidMessage));
    }

    // 3. iOS Payload (APNs VoIP)
    // IMPORTANT: For standard FCM, we use the APNs config with 'voip' type
    // BUT typically for true VoIP on iOS you should use direct APNs or custom logic.
    // However, if you are using FCM to bridge to APNs (if supported) or just needed explicit structure:
    if (iosVoipToken) {
       // Note: Firebase Admin SDK sends to APNs. 
       // If you stored the VoIP token as an FCM registered token (unlikely for pure VoIP), this works.
       // If 'iosVoipToken' is the raw APNs token, you might need a specialized library (like `apn`) 
       // OR use FCM with APNs configuration if you registered the VoIP token with FCM.
       // Assuming here we prioritize using FCM's bridge for simplicity in this template,
       // but strictly speaking, `flutter_callkit_incoming` often implies raw APNs usage for iOS.
       
       // Constructing a payload that matches what CallKeep/CallKit expects
       const iosMessage: admin.messaging.Message = {
         token: iosVoipToken, // This must be an FCM token mapped to the VoIP APNs token, OR use 'apns' library
         apns: {
           headers: {
             "apns-push-type": "voip",
             "apns-priority": "10",
             "apns-topic": "com.example.voip_cross_platform.voip", // Your Bundle ID + .voip
           },
           payload: {
             aps: {
               alert: {
                 title: "Incoming Call",
                 body: `${callerName} is calling you`,
               },
               contentAvailable: true,
             },
             // Custom Data
             uuid: uuid,
             name: callerName,
             handle: callerId,
             hasVideo: hasVideo ? "true" : "false",
           },
         },
       };
       
       console.log(`Sending iOS VoIP to ${calleeId}`);
       promises.push(admin.messaging().send(iosMessage));
    }

    await Promise.all(promises);
    res.status(200).send({ success: true, message: "Call initiated" });

  } catch (error) {
    console.error("Error sending call:", error);
    res.status(500).send(error);
  }
});
