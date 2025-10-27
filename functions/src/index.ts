import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Ajuste: tempo limite e região opcionais
export const cleanAbandonedGames = functions.pubsub
  .schedule("every 15 minutes") // ajuste se preferir
  .onRun(async (context: any) => {
    const oneHourAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 60 * 60 * 1000
    );

    // Consulta: jogos waiting criados antes de oneHourAgo
    // Ajuste o nome da coleção se for outro
    const q = db
      .collection("games")
      .where("status", "==", "waiting")
      .where("createdAt", "<", oneHourAgo)
      .limit(500); // limit para evitar leituras gigantescas por lote

    try {
      const snapshot = await q.get();
      if (snapshot.empty) {
        console.log("Nenhum jogo abandonado encontrado.");
        return null;
      }

      // Firestore batch tem limite de 500 writes por batch
      const batches: admin.firestore.WriteBatch[] = [];
      let batch = db.batch();
      let opCount = 0;

      snapshot.docs.forEach((doc, idx) => {
        batch.update(doc.ref, { status: "canceled" });
        opCount++;

        if (opCount === 500) {
          batches.push(batch);
          batch = db.batch();
          opCount = 0;
        }
      });

      // push último batch se tiver operações pendentes
      if (opCount > 0) batches.push(batch);

      // Commit todos os batches sequencialmente
      for (const b of batches) {
        await b.commit();
      }

      console.log(`${snapshot.size} jogos cancelados por inatividade.`);
      // Agora também verifica jogos 'inprogress' com mais de 2 horas desde a criação
      const twoHoursAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - 2 * 60 * 60 * 1000
      );

      const qInProgress = db
        .collection("games")
        .where("status", "==", "inprogress")
        .where("createdAt", "<", twoHoursAgo)
        .limit(500);

      const snapshotInProgress = await qInProgress.get();
      if (snapshotInProgress.empty) {
        console.log("Nenhum jogo inprogress antigo encontrado.");
        return null;
      }

      const batchesInProgress: admin.firestore.WriteBatch[] = [];
      let batchInProgress = db.batch();
      let opCountInProgress = 0;

      snapshotInProgress.docs.forEach((doc, idx) => {
        batchInProgress.update(doc.ref, { status: "canceled" });
        opCountInProgress++;

        if (opCountInProgress === 500) {
          batchesInProgress.push(batchInProgress);
          batchInProgress = db.batch();
          opCountInProgress = 0;
        }
      });

      if (opCountInProgress > 0) batchesInProgress.push(batchInProgress);

      for (const b of batchesInProgress) {
        await b.commit();
      }

      console.log(
        `${snapshotInProgress.size} jogos inprogress cancelados por inatividade.`
      );
      return null;
    } catch (error) {
      console.error("Erro ao cancelar jogos:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Erro ao cancelar jogos",
        error
      );
    }
  });
