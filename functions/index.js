const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Notifica os produtores quando uma nova encomenda é criada.
 */
exports.onNewOrder = functions.firestore
    .document("orders/{orderId}")
    .onCreate(async (snap, context) => {
      const order = snap.data();
      const producerIds = order.producerIds || [];

      if (producerIds.length === 0) {
        console.log("Nenhum ID de produtor encontrado na encomenda.");
        return null;
      }

      // Procura os tokens de todos os produtores envolvidos.
      const tokens = [];
      for (const producerId of producerIds) {
        try {
          const userDoc = await admin.firestore()
              .collection("users").doc(producerId).get();
          if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.push(userDoc.data().fcmToken);
          }
        } catch (error) {
          console.error("Erro ao buscar o produtor:", producerId, error);
        }
      }

      if (tokens.length === 0) {
        console.log("Nenhum token FCM encontrado para os produtores.");
        return null;
      }

      // Payload da notificação
      const payload = {
        notification: {
          title: "Nova Encomenda!",
          body: `Recebeu uma nova encomenda. Toque para ver os detalhes.`,
        },
        data: {
          orderId: context.params.orderId,
          type: "NEW_ORDER",
        },
      };

      // Envia a notificação para todos os tokens
      try {
        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log("Notificação enviada com sucesso:", response);
      } catch (error) {
        console.error("Erro ao enviar notificação:", error);
      }

      return null;
    });

/**
 * Notifica o consumidor quando o estado da sua encomenda é atualizado.
 */
exports.onOrderStatusUpdate = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Só envia notificação se o estado mudou
      if (before.status === after.status) {
        return null;
      }

      const userId = after.userId;
      if (!userId) {
        console.log("ID do consumidor não encontrado.");
        return null;
      }

      // Busca o token do consumidor
      let token = "";
      try {
        const userDoc = await admin.firestore()
            .collection("users").doc(userId).get();
        if (userDoc.exists && userDoc.data().fcmToken) {
          token = userDoc.data().fcmToken;
        }
      } catch (error) {
        console.error("Erro ao buscar o consumidor:", userId, error);
        return null;
      }

      if (!token) {
        console.log("Token FCM do consumidor não encontrado.");
        return null;
      }

      // Payload da notificação
      const payload = {
        notification: {
          title: "Estado da Encomenda Atualizado",
          body: `O estado da sua encomenda foi atualizado para: ${after.status}`,
        },
        data: {
          orderId: context.params.orderId,
          type: "STATUS_UPDATE",
        },
      };

      // Envia a notificação
      try {
        const response = await admin.messaging().sendToDevice(token, payload);
        console.log("Notificação de estado enviada:", response);
      } catch (error) {
        console.error("Erro ao enviar notificação de estado:", error);
      }

      return null;
    }); 