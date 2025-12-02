import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

const DEFAULT_RATING = 1200;
const MIN_RATING = 100; // Ensures we never fall below a reasonable floor.
const DECAY_RATE = 0.02; // 2% per inactive week.
const WEEK_IN_MS = 7 * 24 * 60 * 60 * 1000;

const AI_RATINGS: Record<string, number> = {
  easy: 900,
  medium: 1200,
  hard: 1500,
};

type LeaderboardDoc = {
  rating: number;
  gamesPlayed: number;
  wins: number;
  losses: number;
  lastMatch?: admin.firestore.Timestamp;
  username?: string;
  photoUrl?: string;
  tier?: string;
  season?: string;
  country?: string;
};

type ParticipantSummary = {
  userId: string;
  username: string | null;
  photoUrl: string | null;
  color: "blue" | "red";
  score: number;
  expectedScore: number;
  previousRating: number;
  newRating: number;
  ratingDelta: number;
  gamesPlayed: number;
  wins: number;
  losses: number;
  kFactor: number;
  tier: string;
  season: string;
  decay?: {
    weeks: number;
    amount: number;
  };
  goldReward?: number;
  goldBalance?: number | null;
};

type UserProfileRecord = {
  username: string | null;
  photoUrl: string | null;
  goldBalance: number;
};

type PlayerColor = "blue" | "red";

type GameDocument = {
  status?: string;
  gameMode?: string;
  currentPlayer?: PlayerColor;
  players?: Record<string, string>;
  currentTurnStartedAt?: FirebaseFirestore.Timestamp;
  currentTurnReminderSentAt?: FirebaseFirestore.Timestamp | null;
};

const INACTIVITY_THRESHOLD_MS = 60 * 1000;
const INACTIVITY_BATCH_LIMIT = 25;
const SUPPORTED_LOCALES = ["en", "es", "pt"] as const;
type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];
const FALLBACK_LOCALE: SupportedLocale = "pt";

const REMINDER_TITLES: Record<SupportedLocale, string> = {
  en: "Your turn",
  es: "Tu turno",
  pt: "Sua vez",
};

const REMINDER_FALLBACK_NAMES: Record<SupportedLocale, string> = {
  en: "Your opponent",
  es: "Tu oponente",
  pt: "Seu oponente",
};

const REMINDER_BODIES: Record<SupportedLocale, (username: string) => string> = {
  en: (username: string) => `${username} is waiting for you to play.`,
  es: (username: string) => `${username} está esperando que juegues.`,
  pt: (username: string) => `${username} está aguardando você jogar.`,
};

const resolveLocale = (value: unknown): SupportedLocale => {
  if (typeof value === "string") {
    const normalized = value.toLowerCase();
    if ((SUPPORTED_LOCALES as readonly string[]).includes(normalized)) {
      return normalized as SupportedLocale;
    }
  }
  return FALLBACK_LOCALE;
};

const ensureOpponentName = (
  locale: SupportedLocale,
  username?: unknown
): string => {
  if (typeof username === "string" && username.trim().length > 0) {
    return username;
  }
  return REMINDER_FALLBACK_NAMES[locale];
};

const extractTokens = (
  data: admin.firestore.DocumentData | undefined | null
): string[] => {
  if (!data) {
    return [];
  }
  const tokens = new Set<string>();
  const latestToken = data.fcmToken;
  if (typeof latestToken === "string" && latestToken.trim().length > 0) {
    tokens.add(latestToken.trim());
  }
  const legacyTokens = data.fcmTokens;
  if (Array.isArray(legacyTokens)) {
    for (const token of legacyTokens) {
      if (typeof token === "string" && token.trim().length > 0) {
        tokens.add(token.trim());
      }
    }
  }
  return Array.from(tokens);
};

const removeInvalidTokens = async (userId: string, tokens: string[]) => {
  if (!tokens.length) {
    return;
  }
  await db
    .collection("users")
    .doc(userId)
    .update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokens),
    })
    .catch((error) => {
      console.error(
        `Erro ao remover tokens inválidos do usuário ${userId}`,
        error
      );
    });
};

const clampRating = (rating: number) =>
  Math.max(MIN_RATING, Math.round(rating));

const expectedScore = (playerRating: number, opponentRating: number) =>
  1 / (1 + Math.pow(10, (opponentRating - playerRating) / 400));

const kFactorFor = (rating: number, gamesPlayed: number) => {
  if (gamesPlayed < 20) {
    return 32;
  }
  if (rating < 1200) {
    return 32;
  }
  if (rating < 1600) {
    return 24;
  }
  return 16;
};

const determineTier = (rating: number): string => {
  if (rating >= 1900) return "diamond";
  if (rating >= 1700) return "platinum";
  if (rating >= 1500) return "gold";
  if (rating >= 1300) return "silver";
  return "bronze";
};

const currentSeason = (now: Date): string => {
  const quarter = Math.floor(now.getUTCMonth() / 3) + 1;
  return `${now.getUTCFullYear()}-Q${quarter}`;
};

const applyDecay = (
  rating: number,
  lastMatch: admin.firestore.Timestamp | undefined,
  now: admin.firestore.Timestamp
) => {
  if (!lastMatch) {
    return { rating, weeks: 0, amount: 0 };
  }
  const diffMs = now.toMillis() - lastMatch.toMillis();
  const inactiveWeeks = Math.floor(diffMs / WEEK_IN_MS);
  if (inactiveWeeks <= 0) {
    return { rating, weeks: 0, amount: 0 };
  }
  const decayAmount = rating * DECAY_RATE * inactiveWeeks;
  const decayedRating = Math.max(MIN_RATING, rating - decayAmount);
  return { rating: decayedRating, weeks: inactiveWeeks, amount: decayAmount };
};

const ensureLeaderboardDoc = (
  data: admin.firestore.DocumentData | undefined
): LeaderboardDoc => {
  if (!data) {
    return {
      rating: DEFAULT_RATING,
      gamesPlayed: 0,
      wins: 0,
      losses: 0,
    };
  }

  const doc: LeaderboardDoc = {
    rating: typeof data.rating === "number" ? data.rating : DEFAULT_RATING,
    gamesPlayed: typeof data.gamesPlayed === "number" ? data.gamesPlayed : 0,
    wins: typeof data.wins === "number" ? data.wins : 0,
    losses: typeof data.losses === "number" ? data.losses : 0,
    lastMatch:
      data.lastMatch instanceof admin.firestore.Timestamp
        ? (data.lastMatch as admin.firestore.Timestamp)
        : undefined,
    username: typeof data.username === "string" ? data.username : undefined,
    photoUrl: typeof data.photoUrl === "string" ? data.photoUrl : undefined,
    tier: typeof data.tier === "string" ? data.tier : undefined,
    season: typeof data.season === "string" ? data.season : undefined,
    country: typeof data.country === "string" ? data.country : undefined,
  };

  return doc;
};

const fetchUserProfile = async (
  txn: admin.firestore.Transaction,
  userId: string
): Promise<UserProfileRecord> => {
  const userRef = db.collection("users").doc(userId);
  const userSnap = await txn.get(userRef);
  if (!userSnap.exists) {
    return { username: null, photoUrl: null, goldBalance: 0 };
  }
  const data = userSnap.data() as {
    username?: string;
    photoUrl?: string;
    goldBalance?: number;
  };
  return {
    username: typeof data?.username === "string" ? data.username : null,
    photoUrl: typeof data?.photoUrl === "string" ? data.photoUrl : null,
    goldBalance: typeof data?.goldBalance === "number" ? data.goldBalance : 0,
  };
};

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

      snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
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

      snapshotInProgress.docs.forEach(
        (doc: admin.firestore.QueryDocumentSnapshot) => {
          batchInProgress.update(doc.ref, { status: "canceled" });
          opCountInProgress++;

          if (opCountInProgress === 500) {
            batchesInProgress.push(batchInProgress);
            batchInProgress = db.batch();
            opCountInProgress = 0;
          }
        }
      );

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

export const updateRanking = functions.https.onCall(
  async (
    data: { gameId?: string } | undefined,
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "O usuário precisa estar autenticado para atualizar o ranking."
      );
    }

    const gameId = typeof data?.gameId === "string" ? data.gameId.trim() : "";
    if (!gameId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Informe o identificador da partida (gameId)."
      );
    }

    const authUid = context.auth.uid;
    const now = admin.firestore.Timestamp.now();
    const season = currentSeason(now.toDate());

    const result = await db.runTransaction(
      async (txn: admin.firestore.Transaction) => {
        const gameRef = db.collection("games").doc(gameId);
        const gameSnap = await txn.get(gameRef);

        if (!gameSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Partida não encontrada."
          );
        }

        const gameData = gameSnap.data() as admin.firestore.DocumentData;
        const status = gameData?.status;
        const winnerColor = gameData?.winner;

        if (status !== "finished" || !winnerColor) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "A partida ainda não foi finalizada."
          );
        }

        const players = (gameData?.players ?? {}) as Record<string, string>;
        const blueId = players.blue;
        const redId = players.red;

        if (blueId !== authUid && redId !== authUid) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Somente participantes da partida podem atualizar o ranking."
          );
        }

        const matchRef = db.collection("match_results").doc(gameId);
        const existingMatch = await txn.get(matchRef);
        if (existingMatch.exists) {
          const stored = existingMatch.data() ?? {};
          return {
            alreadyProcessed: true,
            gameId,
            winner: stored.winner ?? winnerColor,
            participants: stored.participants ?? [],
            processedAt:
              (stored.processedAt as admin.firestore.Timestamp | undefined)
                ?.toDate()
                ?.toISOString() ?? now.toDate().toISOString(),
            aiOpponent: stored.aiOpponent ?? null,
            gameMode: stored.gameMode ?? gameData?.gameMode ?? "online",
          };
        }

        const isBlueWinner = winnerColor === "blue";
        const participantsSummaries: ParticipantSummary[] = [];

        const settingsRef = db.collection("settings").doc("configs");
        const settingsSnap = await txn.get(settingsRef);
        const settingsData =
          (settingsSnap.exists ? settingsSnap.data() : undefined) ?? {};
        const rawGoldValue = settingsData.goldValue;
        const goldRewardAmount =
          typeof rawGoldValue === "number" && Number.isFinite(rawGoldValue)
            ? Math.max(0, Math.round(rawGoldValue))
            : 0;

        const rewardGoldForParticipant = async (
          userId: string,
          currentBalance: number | null,
          isWinner: boolean
        ) => {
          const safeBalance =
            typeof currentBalance === "number" &&
            Number.isFinite(currentBalance)
              ? currentBalance
              : 0;
          const rewardAmount = isWinner
            ? goldRewardAmount
            : Math.floor(goldRewardAmount / 2);

          if (rewardAmount <= 0) {
            return {
              reward: 0,
              balance: safeBalance,
            };
          }

          const updatedBalance = safeBalance + rewardAmount;

          const userRef = db.collection("users").doc(userId);
          txn.set(
            userRef,
            {
              goldBalance: updatedBalance,
              updatedAt: now,
            },
            { merge: true }
          );

          const transactionRef = userRef.collection("gold_transactions").doc();
          txn.set(transactionRef, {
            amount: rewardAmount,
            type: "credit",
            reason: "online_match_reward",
            gameId,
            createdAt: now,
            balanceAfter: updatedBalance,
          });

          return {
            reward: rewardAmount,
            balance: updatedBalance,
          };
        };

        const leaderboardRef = db.collection("leaderboard");

        const loadHumanParticipant = async (
          userId: string,
          color: "blue" | "red",
          opponentRating: number
        ) => {
          const participantRef = leaderboardRef.doc(userId);
          const participantSnap = await txn.get(participantRef);
          const storedData = ensureLeaderboardDoc(participantSnap.data());
          const profile = await fetchUserProfile(txn, userId);
          const decayData = applyDecay(
            storedData.rating,
            storedData.lastMatch,
            now
          );
          const decayedRating = decayData.rating;
          const score =
            color === "blue" ? (isBlueWinner ? 1 : 0) : isBlueWinner ? 0 : 1;
          const expected = expectedScore(decayedRating, opponentRating);
          const kFactor = kFactorFor(decayedRating, storedData.gamesPlayed);
          const updatedRating = clampRating(
            decayedRating + kFactor * (score - expected)
          );
          const updatedGamesPlayed = storedData.gamesPlayed + 1;
          const updatedWins = storedData.wins + (score === 1 ? 1 : 0);
          const updatedLosses = storedData.losses + (score === 0 ? 1 : 0);
          const tier = determineTier(updatedRating);

          const username = profile.username ?? storedData.username ?? null;
          const photoUrl = profile.photoUrl ?? storedData.photoUrl ?? null;

          const seasonToPersist = season;

          const participantData: admin.firestore.UpdateData<admin.firestore.DocumentData> =
            {
              rating: updatedRating,
              gamesPlayed: updatedGamesPlayed,
              wins: updatedWins,
              losses: updatedLosses,
              lastMatch: now,
              username,
              tier,
              season: seasonToPersist,
            };
          if (photoUrl) {
            participantData.photoUrl = photoUrl;
          }

          txn.set(participantRef, participantData, { merge: true });

          const previousRounded = Math.round(decayedRating);
          const isWinner = score === 1;
          const goldData = await rewardGoldForParticipant(
            userId,
            profile.goldBalance,
            isWinner
          );
          participantsSummaries.push({
            userId,
            username,
            photoUrl,
            color,
            score,
            expectedScore: expected,
            previousRating: decayedRating,
            newRating: updatedRating,
            ratingDelta: updatedRating - previousRounded,
            gamesPlayed: updatedGamesPlayed,
            wins: updatedWins,
            losses: updatedLosses,
            kFactor,
            tier,
            season: seasonToPersist,
            decay:
              decayData.weeks > 0
                ? { weeks: decayData.weeks, amount: decayData.amount }
                : undefined,
            goldReward: goldData?.reward ?? 0,
            goldBalance: goldData?.balance ?? null,
          });
        };

        const aiDifficulty =
          typeof gameData?.aiDifficulty === "string"
            ? gameData.aiDifficulty
            : "medium";
        const aiRating = AI_RATINGS[aiDifficulty] ?? AI_RATINGS.medium;
        const isBlueAI = blueId === "ai";
        const isRedAI = redId === "ai";

        if (
          !isBlueAI &&
          typeof blueId === "string" &&
          !isRedAI &&
          typeof redId === "string"
        ) {
          const blueRef = leaderboardRef.doc(blueId);
          const redRef = leaderboardRef.doc(redId);
          const blueSnap = await txn.get(blueRef);
          const redSnap = await txn.get(redRef);

          const blueStored = ensureLeaderboardDoc(blueSnap.data());
          const redStored = ensureLeaderboardDoc(redSnap.data());

          const blueDecay = applyDecay(
            blueStored.rating,
            blueStored.lastMatch,
            now
          );
          const redDecay = applyDecay(
            redStored.rating,
            redStored.lastMatch,
            now
          );

          const blueRating = blueDecay.rating;
          const redRating = redDecay.rating;

          const blueScore = isBlueWinner ? 1 : 0;
          const redScore = 1 - blueScore;

          const blueExpected = expectedScore(blueRating, redRating);
          const redExpected = expectedScore(redRating, blueRating);

          const blueK = kFactorFor(blueRating, blueStored.gamesPlayed);
          const redK = kFactorFor(redRating, redStored.gamesPlayed);

          const newBlueRating = clampRating(
            blueRating + blueK * (blueScore - blueExpected)
          );
          const newRedRating = clampRating(
            redRating + redK * (redScore - redExpected)
          );

          const blueProfile = await fetchUserProfile(txn, blueId);
          const redProfile = await fetchUserProfile(txn, redId);

          const blueUsername =
            blueProfile.username ?? blueStored.username ?? null;
          const bluePhoto = blueProfile.photoUrl ?? blueStored.photoUrl ?? null;
          const redUsername = redProfile.username ?? redStored.username ?? null;
          const redPhoto = redProfile.photoUrl ?? redStored.photoUrl ?? null;

          const blueTier = determineTier(newBlueRating);
          const redTier = determineTier(newRedRating);

          const blueUpdate: admin.firestore.UpdateData<admin.firestore.DocumentData> =
            {
              rating: newBlueRating,
              gamesPlayed: blueStored.gamesPlayed + 1,
              wins: blueStored.wins + (blueScore === 1 ? 1 : 0),
              losses: blueStored.losses + (blueScore === 0 ? 1 : 0),
              lastMatch: now,
              username: blueUsername,
              tier: blueTier,
              season,
            };
          if (bluePhoto) {
            blueUpdate.photoUrl = bluePhoto;
          }

          const redUpdate: admin.firestore.UpdateData<admin.firestore.DocumentData> =
            {
              rating: newRedRating,
              gamesPlayed: redStored.gamesPlayed + 1,
              wins: redStored.wins + (redScore === 1 ? 1 : 0),
              losses: redStored.losses + (redScore === 0 ? 1 : 0),
              lastMatch: now,
              username: redUsername,
              tier: redTier,
              season,
            };
          if (redPhoto) {
            redUpdate.photoUrl = redPhoto;
          }

          txn.set(blueRef, blueUpdate, { merge: true });
          txn.set(redRef, redUpdate, { merge: true });

          const blueGoldData = await rewardGoldForParticipant(
            blueId,
            blueProfile.goldBalance,
            isBlueWinner
          );
          const redGoldData = await rewardGoldForParticipant(
            redId,
            redProfile.goldBalance,
            !isBlueWinner
          );

          participantsSummaries.push({
            userId: blueId,
            username: blueUsername,
            photoUrl: bluePhoto,
            color: "blue",
            score: blueScore,
            expectedScore: blueExpected,
            previousRating: blueRating,
            newRating: newBlueRating,
            ratingDelta: newBlueRating - Math.round(blueRating),
            gamesPlayed: blueStored.gamesPlayed + 1,
            wins: blueStored.wins + (blueScore === 1 ? 1 : 0),
            losses: blueStored.losses + (blueScore === 0 ? 1 : 0),
            kFactor: blueK,
            tier: blueTier,
            season,
            decay:
              blueDecay.weeks > 0
                ? { weeks: blueDecay.weeks, amount: blueDecay.amount }
                : undefined,
            goldReward: blueGoldData?.reward ?? 0,
            goldBalance: blueGoldData?.balance ?? null,
          });

          participantsSummaries.push({
            userId: redId,
            username: redUsername,
            photoUrl: redPhoto,
            color: "red",
            score: redScore,
            expectedScore: redExpected,
            previousRating: redRating,
            newRating: newRedRating,
            ratingDelta: newRedRating - Math.round(redRating),
            gamesPlayed: redStored.gamesPlayed + 1,
            wins: redStored.wins + (redScore === 1 ? 1 : 0),
            losses: redStored.losses + (redScore === 0 ? 1 : 0),
            kFactor: redK,
            tier: redTier,
            season,
            decay:
              redDecay.weeks > 0
                ? { weeks: redDecay.weeks, amount: redDecay.amount }
                : undefined,
            goldReward: redGoldData?.reward ?? 0,
            goldBalance: redGoldData?.balance ?? null,
          });
        } else if (!isBlueAI && typeof blueId === "string") {
          await loadHumanParticipant(blueId, "blue", aiRating);
        } else if (!isRedAI && typeof redId === "string") {
          await loadHumanParticipant(redId, "red", aiRating);
        } else {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Não há jogadores humanos para atualizar o ranking."
          );
        }

        const matchPayload: Record<string, unknown> = {
          gameId,
          processedAt: now,
          winner: winnerColor,
          participants: participantsSummaries.map((participant) => ({
            userId: participant.userId,
            username: participant.username,
            photoUrl: participant.photoUrl,
            color: participant.color,
            score: participant.score,
            expectedScore: Number(participant.expectedScore.toFixed(4)),
            previousRating: Math.round(participant.previousRating),
            newRating: participant.newRating,
            ratingDelta: participant.ratingDelta,
            gamesPlayed: participant.gamesPlayed,
            wins: participant.wins,
            losses: participant.losses,
            kFactor: participant.kFactor,
            tier: participant.tier,
            season: participant.season,
            decay: participant.decay
              ? {
                  weeks: participant.decay.weeks,
                  amount: Number(participant.decay.amount.toFixed(2)),
                }
              : null,
            goldReward: participant.goldReward ?? 0,
            goldBalance: participant.goldBalance ?? null,
          })),
          gameMode: gameData?.gameMode ?? "online",
        };

        if (isBlueAI || isRedAI) {
          matchPayload.aiOpponent = {
            difficulty: aiDifficulty,
            rating: aiRating,
          };
        }

        txn.set(matchRef, matchPayload, { merge: false });
        txn.update(gameRef, { rankingProcessed: true });

        return {
          alreadyProcessed: false,
          gameId,
          winner: winnerColor,
          participants: matchPayload.participants,
          processedAt: now.toDate().toISOString(),
          aiOpponent: matchPayload.aiOpponent ?? null,
          gameMode: matchPayload.gameMode,
        };
      }
    );

    return result;
  }
);

export const adjustPvaiDifficulty = functions.firestore
  .document("games/{gameId}")
  .onUpdate(async (change) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!afterData) {
      return null;
    }

    const beforeGameMode = beforeData?.gameMode;
    const afterGameMode = afterData.gameMode;
    const beforePlayers = (beforeData?.players ?? {}) as Record<
      string,
      unknown
    >;
    const afterPlayers = (afterData.players ?? {}) as Record<string, unknown>;

    const beforeRed =
      typeof beforePlayers.red === "string" ? beforePlayers.red : undefined;
    const afterRed =
      typeof afterPlayers.red === "string" ? afterPlayers.red : undefined;

    const hasRelevantChange =
      afterGameMode === "pvai" &&
      afterRed === "ai" &&
      (beforeGameMode !== afterGameMode || beforeRed !== afterRed);

    if (!hasRelevantChange) {
      return null;
    }

    const blueId =
      typeof afterPlayers.blue === "string" ? afterPlayers.blue : undefined;

    if (!blueId || blueId === "ai") {
      return null;
    }

    const leaderboardSnap = await db
      .collection("leaderboard")
      .doc(blueId)
      .get();
    const leaderboardData = ensureLeaderboardDoc(leaderboardSnap.data());

    if (leaderboardData.rating < 1700) {
      return null;
    }

    if (afterData.aiDifficulty === "hard") {
      return null;
    }

    await change.after.ref.update({ aiDifficulty: "hard" });

    return null;
  });

export const resetTurnMetadata = functions.firestore
  .document("games/{gameId}")
  .onUpdate(async (change) => {
    const beforeData = change.before.data() as GameDocument | undefined;
    const afterData = change.after.data() as GameDocument | undefined;

    if (!afterData) {
      return null;
    }

    if (afterData.status !== "inprogress") {
      return null;
    }

    const beforePlayer = beforeData?.currentPlayer;
    const afterPlayer = afterData.currentPlayer;
    const statusChanged = beforeData?.status !== afterData.status;
    const playerChanged = beforePlayer !== afterPlayer;

    if (!statusChanged && !playerChanged) {
      return null;
    }

    await change.after.ref.update({
      currentTurnStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      currentTurnReminderSentAt: null,
    });

    return null;
  });

export const sendTurnInactivityReminders = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const threshold = admin.firestore.Timestamp.fromMillis(
      Date.now() - INACTIVITY_THRESHOLD_MS
    );

    const snapshot = await db
      .collection("games")
      .where("status", "==", "inprogress")
      .where("gameMode", "==", "online")
      .where("currentTurnStartedAt", "<=", threshold)
      .where("currentTurnReminderSentAt", "==", null)
      .limit(INACTIVITY_BATCH_LIMIT)
      .get();

    if (snapshot.empty) {
      return null;
    }

    for (const doc of snapshot.docs) {
      await processReminder(doc).catch((error) => {
        console.error(`Erro ao enviar lembrete para o jogo ${doc.id}`, error);
      });
    }

    return null;
  });

const processReminder = async (
  doc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
) => {
  const data = doc.data() as GameDocument;
  const players = data.players ?? {};
  const currentPlayer = data.currentPlayer;

  if (currentPlayer !== "blue" && currentPlayer !== "red") {
    return;
  }

  const targetUid = players[currentPlayer];
  if (!targetUid || targetUid === "ai") {
    await doc.ref.update({
      currentTurnReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const waitingColor: PlayerColor = currentPlayer === "blue" ? "red" : "blue";
  const waitingUid = players[waitingColor];

  const [targetSnap, waitingSnap] = await Promise.all([
    db.collection("users").doc(targetUid).get(),
    waitingUid
      ? db.collection("users").doc(waitingUid).get()
      : Promise.resolve(null),
  ]);

  const targetData = targetSnap.data();
  const tokens = extractTokens(targetData);

  const locale = resolveLocale(targetData?.preferredLocale);
  const opponentName = ensureOpponentName(
    locale,
    waitingSnap?.data()?.username
  );

  const title = REMINDER_TITLES[locale];
  const body = REMINDER_BODIES[locale](opponentName);

  if (!tokens.length) {
    await doc.ref.update({
      currentTurnReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      type: "opponent_waiting",
      opponentUsername: opponentName,
      gameId: doc.id,
      waitingColor,
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  const invalidTokens = response.responses
    .map((res, index) => {
      if (res.success) {
        return null;
      }
      const errorCode = res.error?.code ?? "";
      if (errorCode === "messaging/registration-token-not-registered") {
        return tokens[index];
      }
      return null;
    })
    .filter((token): token is string => Boolean(token));

  if (invalidTokens.length) {
    await removeInvalidTokens(targetUid, invalidTokens);
  }

  await doc.ref.update({
    currentTurnReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};
