/**
 * Apaga todos os documentos das coleções operacionais do DOFLUXO.
 *
 * Uso:
 *   1. Console Firebase → Configurações → Contas de serviço → Gerar nova chave privada
 *   2. Salve como scripts/serviceAccountKey.json (não commitar)
 *   3. npm install --no-save firebase-admin
 *   4. node scripts/wipe_firestore_data.mjs
 *
 * Mantém: contas do Firebase Auth (login Google).
 * Remove: agencies, memberships, clients, projects, users, settings
 */
import { readFileSync, existsSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const PROJECT_ID = 'dofluxo-organizer';
const COLLECTIONS = ['clients', 'projects', 'agencies', 'memberships', 'users', 'settings'];
const KEY_PATH = new URL('./serviceAccountKey.json', import.meta.url);

if (!existsSync(KEY_PATH)) {
  console.error(
    'Chave não encontrada: scripts/serviceAccountKey.json\n' +
      'Baixe em Firebase Console → Configurações do projeto → Contas de serviço → Gerar nova chave privada',
  );
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(KEY_PATH, 'utf8'));

initializeApp({
  credential: cert(serviceAccount),
  projectId: PROJECT_ID,
});

const db = getFirestore();

async function deleteCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) {
    console.log(`  ${collectionName}: (vazio)`);
    return 0;
  }

  let deleted = 0;
  const batchSize = 450;

  for (let i = 0; i < snapshot.docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = snapshot.docs.slice(i, i + batchSize);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }

  console.log(`  ${collectionName}: ${deleted} documento(s) apagado(s)`);
  return deleted;
}

async function main() {
  console.log(`Limpando Firestore — projeto ${PROJECT_ID}\n`);

  let total = 0;
  for (const name of COLLECTIONS) {
    total += await deleteCollection(name);
  }

  console.log(`\nConcluído. ${total} documento(s) removido(s).`);
  console.log('Faça logout/login no app para passar pelo wizard de nova agência.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
