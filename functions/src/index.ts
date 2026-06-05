import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const REGION = "europe-west1";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function getFcmToken(userId: string): Promise<string | null> {
  const snap = await db.collection("users").doc(userId).get();
  return snap.exists ? (snap.data()?.fcmToken ?? null) : null;
}

interface NotificationPayload {
  title: string;
  body: string;
  type: string;
  targetId?: string;
}

async function sendPush(
  recipientId: string,
  payload: NotificationPayload
): Promise<void> {
  const token = await getFcmToken(recipientId);
  if (!token) {
    console.log(`[push] No FCM token for user ${recipientId} — skipping.`);
    return;
  }

  const data: Record<string, string> = { type: payload.type };
  if (payload.targetId) data["targetId"] = payload.targetId;

  await messaging.send({
    token,
    notification: { title: payload.title, body: payload.body },
    apns: {
      payload: { aps: { sound: "default", badge: 1 } },
    },
    data,
  });

  console.log(`[push] Sent "${payload.type}" to user ${recipientId}.`);
}

// ---------------------------------------------------------------------------
// 1. Coach trimite un assignment → notifică clientul
// ---------------------------------------------------------------------------

export const onAssignmentCreated = onDocumentCreated(
  { document: "assignments/{assignmentId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { clientId, title, emoji } = data;
    if (!clientId || !title) return;

    const label = emoji ? `${emoji} ${title}` : title;
    await sendPush(clientId, {
      title: "Assignment nou",
      body: `Coach-ul tău ți-a trimis: ${label}`,
      type: "assignment_received",
      targetId: event.params.assignmentId,
    });
  }
);

// ---------------------------------------------------------------------------
// 2. Client completează un assignment → notifică coach-ul
// ---------------------------------------------------------------------------

export const onAssignmentCompletionCreated = onDocumentCreated(
  { document: "assignmentCompletions/{completionId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { coachId, clientId, assignmentTitle } = data;
    if (!coachId || !clientId || !assignmentTitle) return;

    const clientSnap = await db.collection("users").doc(clientId).get();
    const clientName: string = clientSnap.data()?.displayName ?? "Clientul";

    await sendPush(coachId, {
      title: "Completare nouă",
      body: `${clientName} a completat: ${assignmentTitle}`,
      type: "assignment_completed",
      targetId: event.params.completionId,
    });
  }
);

// ---------------------------------------------------------------------------
// 3. Coach comentează pe o completare  → notifică clientul
// 4. Client răspunde în thread         → notifică coach-ul
// ---------------------------------------------------------------------------

export const onAssignmentCompletionUpdated = onDocumentUpdated(
  { document: "assignmentCompletions/{completionId}", region: REGION },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const { clientId, coachId, assignmentTitle } = after;

    // 3. Coach a adăugat/modificat coachReply
    if ((after.coachReply ?? "") !== (before.coachReply ?? "") && after.coachReply) {
      await sendPush(clientId, {
        title: `Răspuns la ${assignmentTitle}`,
        body: after.coachReply,
        type: "coach_replied",
        targetId: event.params.completionId,
      });
    }

    // 4. Mesaj nou în thread
    const beforeMessages: any[] = before.messages ?? [];
    const afterMessages: any[] = after.messages ?? [];
    if (afterMessages.length > beforeMessages.length) {
      const lastMsg = afterMessages[afterMessages.length - 1];
      if (lastMsg?.role === "client" && lastMsg?.text) {
        await sendPush(coachId, {
          title: `Mesaj nou — ${assignmentTitle}`,
          body: lastMsg.text,
          type: "client_replied",
          targetId: event.params.completionId,
        });
      }
      if (lastMsg?.role === "coach" && lastMsg?.text) {
        await sendPush(clientId, {
          title: `Răspuns — ${assignmentTitle}`,
          body: lastMsg.text,
          type: "coach_replied",
          targetId: event.params.completionId,
        });
      }
    }
  }
);

// ---------------------------------------------------------------------------
// 5. Coach trimite un obiectiv → notifică clientul
// ---------------------------------------------------------------------------

export const onGoalCreated = onDocumentCreated(
  { document: "goals/{goalId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (!data.createdByCoach || !data.userId || !data.title) return;

    const label = data.emoji ? `${data.emoji} ${data.title}` : data.title;
    await sendPush(data.userId, {
      title: "Obiectiv nou de la coach",
      body: label,
      type: "goal_received",
      targetId: event.params.goalId,
    });
  }
);

// ---------------------------------------------------------------------------
// 6. Coach trimite un feedback form → notifică clientul
// ---------------------------------------------------------------------------

export const onFeedbackFormCreated = onDocumentCreated(
  { document: "feedbackForms/{formId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { clientId, questionIds } = data;
    if (!clientId) return;

    const count: number = Array.isArray(questionIds) ? questionIds.length : 0;
    await sendPush(clientId, {
      title: "Feedback de completat",
      body: `Coach-ul tău ți-a trimis un formular cu ${count} ${count === 1 ? "întrebare" : "întrebări"}.`,
      type: "feedback_form_received",
      targetId: event.params.formId,
    });
  }
);

// ---------------------------------------------------------------------------
// 7. Client trimite un feedback → notifică coach-ul
// ---------------------------------------------------------------------------

export const onFeedbackResponseCreated = onDocumentCreated(
  { document: "feedbackResponses/{responseId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { coachId, clientId } = data;
    if (!coachId || !clientId) return;

    const clientSnap = await db.collection("users").doc(clientId).get();
    const clientName: string = clientSnap.data()?.displayName ?? "Clientul";

    await sendPush(coachId, {
      title: "Feedback primit",
      body: `${clientName} a completat formularul de feedback.`,
      type: "feedback_submitted",
      targetId: event.params.responseId,
    });
  }
);

// ---------------------------------------------------------------------------
// 8. Client loghează sesiune → notifică coach-ul
// 9. Coach loghează sesiune → notifică clientul
// ---------------------------------------------------------------------------

export const onCoachingSessionCreated = onDocumentCreated(
  { document: "coachingSessions/{sessionId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { userId, coachId } = data;

    if (coachId) {
      // Coach-logged → notify client
      const coachSnap = await db.collection("users").doc(coachId).get();
      const coachName: string = coachSnap.data()?.displayName ?? "Coach-ul";

      await sendPush(userId, {
        title: "Sesiune înregistrată",
        body: `${coachName} a înregistrat sesiunea voastră de coaching.`,
        type: "session_logged_by_coach",
        targetId: event.params.sessionId,
      });
    } else {
      // Client-logged → notify coach
      const clientSnap = await db.collection("users").doc(userId).get();
      const clientData = clientSnap.data();
      const linkedCoachId: string | undefined = clientData?.coachId;
      const clientName: string = clientData?.displayName ?? "Clientul";

      if (!linkedCoachId) return;

      await sendPush(linkedCoachId, {
        title: "Sesiune nouă",
        body: `${clientName} a logat o sesiune de coaching.`,
        type: "session_logged_by_client",
        targetId: event.params.sessionId,
      });
    }
  }
);
