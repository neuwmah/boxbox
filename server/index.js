'use strict';

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const cors = require('cors');
const express = require('express');
const rateLimit = require('express-rate-limit');
const { body, param, validationResult } = require('express-validator');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

const { initFirebase, authenticate } = require('./auth');

const app = express();
app.set('trust proxy', 1);
const PORT = Number(process.env.PORT) || 3000;
const INITIAL = {
  current_level: 1,
  coins: 500,
  hearts: 5,
  no_ads: false,
  updated_at: 0,
};

initFirebase();

const origins = String(process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: origins.includes('*') ? true : origins,
  }),
);
app.use(express.json({ limit: '32kb' }));
app.use(
  rateLimit({
    windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 60_000,
    max: Number(process.env.RATE_LIMIT_MAX) || 100,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

function loadAivenCa() {
  const fromEnv = (process.env.AIVEN_CA || '').trim();
  if (fromEnv) {
    if (fromEnv.startsWith('-----BEGIN')) {
      return fromEnv.replace(/\\n/g, '\n');
    }
    const decoded = Buffer.from(fromEnv, 'base64').toString('utf8');
    if (decoded.includes('BEGIN CERTIFICATE')) return decoded;
  }
  const file = process.env.AIVEN_CA_FILE || path.join(__dirname, 'ca.pem');
  if (fs.existsSync(file)) return fs.readFileSync(file, 'utf8');
  return undefined;
}

function databaseUrl() {
  return String(process.env.DATABASE_URL || '')
    .replace(/[?&]sslmode=[^&]*/g, '')
    .replace(/[?&]sslrootcert=[^&]*/g, '')
    .replace(/[?&]channel_binding=[^&]*/g, '')
    .replace(/\?&/, '?')
    .replace(/[?&]$/, '');
}

const aivenCa = loadAivenCa();
if (aivenCa) {
  console.log('Aiven CA loaded');
} else {
  console.warn('Aiven CA not found. Set AIVEN_CA or add ca.pem next to index.js.');
}

const pool = new Pool({
  connectionString: databaseUrl(),
  ssl: {
    rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
    ca: aivenCa,
  },
});

function toUnix(value) {
  if (value == null) return 0;
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const ms = new Date(value).getTime();
  return Number.isFinite(ms) ? Math.trunc(ms / 1000) : 0;
}

function toPlayer(row) {
  return {
    id: row.id,
    player_id: row.player_id,
    current_level: row.current_level,
    coins: row.coins,
    hearts: row.hearts,
    no_ads: row.no_ads,
    updated_at: toUnix(row.updatedAt),
  };
}

function toInt(value, fallback) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.trunc(n);
}

function parseSaveBody(body, fallback = INITIAL) {
  return {
    current_level: Math.max(
      1,
      Math.min(9999, toInt(body?.current_level, fallback.current_level)),
    ),
    coins: Math.max(0, Math.min(999999, toInt(body?.coins, fallback.coins))),
    hearts: Math.max(0, Math.min(5, toInt(body?.hearts, fallback.hearts))),
    no_ads: body?.no_ads == null ? fallback.no_ads : Boolean(body.no_ads),
    updated_at: Math.max(
      0,
      toInt(body?.updated_at, toUnix(fallback.updated_at ?? fallback.updatedAt)),
    ),
  };
}

function rejectInvalid(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: 'Invalid fields', errors: errors.array() });
  }
  return next();
}

const saveValidators = [
  body('current_level').optional().isInt({ min: 1, max: 9999 }),
  body('coins').optional().isInt({ min: 0, max: 999999 }),
  body('hearts').optional().isInt({ min: 0, max: 5 }),
  body('no_ads').optional().isBoolean(),
  body('updated_at').optional().isInt({ min: 0 }),
];

const playerIdParam = param('playerId').isUUID(4);

async function findByPlayerId(playerId) {
  const { rows } = await pool.query(
    `SELECT id, player_id, firebase_uid, current_level, coins, hearts, no_ads, "updatedAt"
     FROM "Player" WHERE player_id = $1`,
    [playerId],
  );
  return rows[0] ?? null;
}

async function findByUid(uid) {
  const { rows } = await pool.query(
    `SELECT id, player_id, firebase_uid, current_level, coins, hearts, no_ads, "updatedAt"
     FROM "Player" WHERE firebase_uid = $1`,
    [uid],
  );
  return rows[0] ?? null;
}

async function createPlayer(uid, save = INITIAL) {
  const playerId = uuidv4();
  const updatedAt = save.updated_at > 0 ? save.updated_at : Math.trunc(Date.now() / 1000);
  const inserted = await pool.query(
    `INSERT INTO "Player"
      (id, player_id, firebase_uid, current_level, coins, hearts, no_ads, "createdAt", "updatedAt")
     VALUES (gen_random_uuid()::text, $1, $2, $3, $4, $5, $6, NOW(), to_timestamp($7))
     RETURNING id, player_id, firebase_uid, current_level, coins, hearts, no_ads, "updatedAt"`,
    [playerId, uid, save.current_level, save.coins, save.hearts, save.no_ads, updatedAt],
  );
  return inserted.rows[0];
}

async function updatePlayer(playerId, save) {
  const updated = await pool.query(
    `UPDATE "Player"
     SET current_level = $2, coins = $3, hearts = $4, no_ads = $5, "updatedAt" = to_timestamp($6)
     WHERE player_id = $1
     RETURNING id, player_id, firebase_uid, current_level, coins, hearts, no_ads, "updatedAt"`,
    [playerId, save.current_level, save.coins, save.hearts, save.no_ads, save.updated_at],
  );
  return updated.rows[0] ?? null;
}

async function requireOwnPlayer(req, res, next) {
  try {
    const playerId = String(req.params.playerId || '').trim();
    const row = await findByPlayerId(playerId);
    if (!row) {
      return res.status(404).json({ message: 'Player not found' });
    }
    if (row.firebase_uid !== req.firebaseUid) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    req.player = row;
    return next();
  } catch (error) {
    console.error('Authorization failed:', error);
    return res.status(500).json({ message: 'Internal error' });
  }
}

function applyLastWriteWins(existing, incoming, res) {
  if (incoming.updated_at <= toUnix(existing.updatedAt ?? existing.updated_at)) {
    res.status(409).json({ message: 'Conflict', server: toPlayer(existing) });
    return null;
  }
  return incoming;
}

async function setupDb() {
  await pool.query(`
    ALTER TABLE "Player" ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE
  `);
  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_player_firebase_uid ON "Player"(firebase_uid)
  `);
  await pool.query(`
    ALTER TABLE "Player" DROP COLUMN IF EXISTS last
  `);
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/me', authenticate, async (req, res) => {
  try {
    let row = await findByUid(req.firebaseUid);
    if (!row) {
      return res.status(404).json({ message: 'Player not found' });
    }
    return res.json(toPlayer(row));
  } catch (error) {
    console.error('GET /me failed:', error);
    return res.status(500).json({ message: 'Internal error' });
  }
});

app.put('/me', authenticate, saveValidators, rejectInvalid, async (req, res) => {
  try {
    let row = await findByUid(req.firebaseUid);
    if (!row) {
      row = await createPlayer(req.firebaseUid, parseSaveBody(req.body));
      return res.json(toPlayer(row));
    }
    const save = parseSaveBody(req.body, row);
    if (!applyLastWriteWins(row, save, res)) return;
    const updated = await updatePlayer(row.player_id, save);
    return res.json(toPlayer(updated));
  } catch (error) {
    console.error('PUT /me failed:', error);
    return res.status(500).json({ message: 'Internal error' });
  }
});

app.get(
  '/players/:playerId',
  authenticate,
  playerIdParam,
  rejectInvalid,
  requireOwnPlayer,
  (req, res) => {
    return res.json(toPlayer(req.player));
  },
);

app.post('/players', authenticate, saveValidators, rejectInvalid, async (req, res) => {
  try {
    const existing = await findByUid(req.firebaseUid);
    if (existing) {
      return res.status(409).json({
        message: 'Player already exists',
        server: toPlayer(existing),
      });
    }
    const created = await createPlayer(req.firebaseUid, parseSaveBody(req.body));
    return res.status(201).json(toPlayer(created));
  } catch (error) {
    if (error.code === '23505') {
      const existing = await findByUid(req.firebaseUid);
      return res.status(409).json({
        message: 'Player already exists',
        server: existing ? toPlayer(existing) : null,
      });
    }
    console.error('POST /players failed:', error);
    return res.status(500).json({ message: 'Internal error' });
  }
});

app.put(
  '/players/:playerId',
  authenticate,
  playerIdParam,
  saveValidators,
  rejectInvalid,
  requireOwnPlayer,
  async (req, res) => {
    try {
      const save = parseSaveBody(req.body, req.player);
      if (!applyLastWriteWins(req.player, save, res)) return;
      const updated = await updatePlayer(req.player.player_id, save);
      return res.json(toPlayer(updated));
    } catch (error) {
      console.error('PUT /players failed:', error);
      return res.status(500).json({ message: 'Internal error' });
    }
  },
);

setupDb()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log('BoxBox! by 2014');
    });
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
