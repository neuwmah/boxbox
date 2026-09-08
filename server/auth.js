'use strict';

const admin = require('firebase-admin');

function initFirebase() {
  if (admin.apps.length) return;

  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (b64) {
    const json = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(json),
      projectId: process.env.FIREBASE_PROJECT_ID || json.project_id,
    });
    return;
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

async function authenticate(req, res, next) {
  const header = String(req.headers.authorization || '');
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ message: 'Token required' });
  }
  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.firebaseUid = decoded.uid;
    return next();
  } catch (error) {
    console.error('Token invalid:', error.message);
    return res.status(403).json({ message: 'Invalid token' });
  }
}

module.exports = { initFirebase, authenticate };
