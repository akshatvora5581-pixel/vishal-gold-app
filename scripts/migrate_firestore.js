/**
 * Firestore Migration Script: vishal-gold-app -> vishal-jewelers-app
 * 
 * This script migrates all documents from specified collections.
 * 
 * Prerequisites:
 * 1. Place 'old-service-account.json' and 'new-service-account.json' in the same folder.
 * 2. Run: npm install firebase-admin
 */

const admin = require('firebase-admin');

// 1. Initialize OLD Project
const oldApp = admin.initializeApp({
  credential: admin.credential.cert(require('./old-service-account.json'))
}, 'old-app');

// 2. Initialize NEW Project
const newApp = admin.initializeApp({
  credential: admin.credential.cert(require('./new-service-account.json'))
}, 'new-app');

const oldDB = oldApp.firestore();
const newDB = newApp.firestore();

// --- Collections to Migrate ---
const collections = ['banners', 'categories', 'products', 'sub_categories'];

async function migrateCollection(collectionName) {
  console.log(`\n--- Starting Migration for: ${collectionName} ---`);
  
  const snapshot = await oldDB.collection(collectionName).get();
  
  if (snapshot.empty) {
    console.log(`[!] Collection ${collectionName} is empty. Skipping.`);
    return;
  }

  console.log(`[*] Found ${snapshot.size} documents in ${collectionName}.`);

  const batchSize = 100;
  let batch = newDB.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const docRef = newDB.collection(collectionName).doc(doc.id);
    
    batch.set(docRef, data);
    count++;

    if (count % batchSize === 0) {
      await batch.commit();
      batch = newDB.batch();
      console.log(`[+] Committed ${count} documents...`);
    }
  }

  if (count % batchSize !== 0) {
    await batch.commit();
  }

  console.log(`[SUCCESS] Migrated ${count} documents for ${collectionName}.`);
}

async function runMigration() {
  try {
    for (const collection of collections) {
      await migrateCollection(collection);
    }
    console.log('\n=======================================');
    console.log('MIGRATION COMPLETED SUCCESSFULLY!');
    console.log('=======================================');
  } catch (error) {
    console.error('[CRITICAL ERROR] Migration failed:', error);
  }
}

runMigration();
