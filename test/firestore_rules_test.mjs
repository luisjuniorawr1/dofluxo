/**

 * Validação local das Firestore Rules (modelo membership-only).

 * Executar: npx firebase emulators:exec --only firestore "node test/firestore_rules_test.mjs"

 */

import { readFileSync } from 'node:fs';

import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';

import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, query, where } from 'firebase/firestore';



const PROJECT_ID = 'dofluxo-rules-test';

const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');



const OWNER_UID = 'owner-user-abc';

const MEMBER_UID = 'member-user-def';

const OTHER_UID = 'other-user-xyz';

const AGENCY_ID = 'agency-uuid-111';



let testEnv;



async function setup() {

  testEnv = await initializeTestEnvironment({

    projectId: PROJECT_ID,

    firestore: { rules },

  });

}



async function cleanup() {

  if (testEnv) await testEnv.cleanup();

}



async function ownerDb() {

  return testEnv.authenticatedContext(OWNER_UID).firestore();

}



async function memberDb() {

  return testEnv.authenticatedContext(MEMBER_UID).firestore();

}



async function outsiderDb() {

  return testEnv.authenticatedContext(OTHER_UID).firestore();

}



async function seedBaseData() {

  await testEnv.withSecurityRulesDisabled(async (context) => {

    const db = context.firestore();

    await setDoc(doc(db, `agencies/${AGENCY_ID}`), {

      name: 'Agência Teste',

      ownerId: OWNER_UID,

      createdBy: OWNER_UID,

      primaryColor: '4294967295',

    });

    await setDoc(doc(db, `memberships/${AGENCY_ID}_${OWNER_UID}`), {

      agencyId: AGENCY_ID,

      userId: OWNER_UID,

      role: 'owner',

      status: 'active',

      agencyName: 'Agência Teste',

      userEmail: 'owner@test.com',

    });

    await setDoc(doc(db, `memberships/${AGENCY_ID}_${MEMBER_UID}`), {

      agencyId: AGENCY_ID,

      userId: MEMBER_UID,

      role: 'member',

      status: 'active',

      agencyName: 'Agência Teste',

      userEmail: 'member@test.com',

    });

    await setDoc(doc(db, 'clients/c1'), {

      agencyId: AGENCY_ID,

      name: 'Cliente',

      createdAt: new Date(),

    });

    await setDoc(doc(db, 'projects/p1'), {

      agencyId: AGENCY_ID,

      title: 'Projeto',

      createdAt: new Date(),

    });

  });

}



const tests = [];



function test(name, fn) {

  tests.push({ name, fn });

}



test('owner: CRUD client da agência', async () => {

  const db = await ownerDb();

  await assertSucceeds(getDoc(doc(db, 'clients/c1')));

  await assertSucceeds(

    setDoc(doc(db, 'clients/c-new'), {

      agencyId: AGENCY_ID,

      name: 'Novo',

      createdAt: new Date(),

    }),

  );

  await assertSucceeds(updateDoc(doc(db, 'clients/c1'), { name: 'Atualizado' }));

  await assertSucceeds(deleteDoc(doc(db, 'clients/c-new')));

});



test('outsider: negado em client da agência', async () => {

  const db = await outsiderDb();

  await assertFails(getDoc(doc(db, 'clients/c1')));

});



test('member: acessa client da agência', async () => {

  const db = await memberDb();

  await assertSucceeds(getDoc(doc(db, 'clients/c1')));

});



test('bootstrap: create agency + membership owner', async () => {

  const db = await ownerDb();

  const newAgencyId = 'new-agency-222';

  await assertSucceeds(

    setDoc(doc(db, `agencies/${newAgencyId}`), {

      name: 'Nova Agência',

      ownerId: OWNER_UID,

      createdBy: OWNER_UID,

      primaryColor: '4294967295',

    }),

  );

  await assertSucceeds(

    setDoc(doc(db, `memberships/${newAgencyId}_${OWNER_UID}`), {

      agencyId: newAgencyId,

      userId: OWNER_UID,

      role: 'owner',

      status: 'active',

      agencyName: 'Nova Agência',

      userEmail: 'owner@test.com',

    }),

  );

});



test('bootstrap: list memberships por userId + status', async () => {

  const db = await ownerDb();

  const q = query(

    collection(db, 'memberships'),

    where('userId', '==', OWNER_UID),

    where('status', '==', 'active'),

  );

  await assertSucceeds(getDocs(q));

});



test('owner: atualiza branding agencies + membership denorm', async () => {

  const db = await ownerDb();

  await assertSucceeds(

    updateDoc(doc(db, `agencies/${AGENCY_ID}`), {

      name: 'Agência Atualizada',

      primaryColor: '4278190335',

    }),

  );

  await assertSucceeds(

    updateDoc(doc(db, `memberships/${AGENCY_ID}_${OWNER_UID}`), {

      agencyName: 'Agência Atualizada',

    }),

  );

});



test('settings: deny read/write', async () => {

  const db = await ownerDb();

  await assertFails(getDoc(doc(db, `settings/${OWNER_UID}`)));

  await assertFails(

    setDoc(doc(db, `settings/${OWNER_UID}`), {

      agencyName: 'X',

      primaryColor: '1',

    }),

  );

});



test('users: perfil próprio read/write', async () => {

  const db = await ownerDb();

  await assertSucceeds(

    setDoc(doc(db, `users/${OWNER_UID}`), {

      displayName: 'Owner',

      email: 'owner@test.com',

    }),

  );

});



async function run() {

  let passed = 0;

  let failed = 0;



  await setup();

  await seedBaseData();



  for (const { name, fn } of tests) {

    try {

      await fn();

      console.log(`  ✓ ${name}`);

      passed++;

    } catch (error) {

      console.error(`  ✗ ${name}`);

      console.error(`    ${error.message}`);

      failed++;

    } finally {

      await testEnv.clearFirestore();

      await seedBaseData();

    }

  }



  await cleanup();



  console.log(`\n${passed} passed, ${failed} failed`);

  process.exit(failed > 0 ? 1 : 0);

}



run().catch((error) => {

  console.error(error);

  process.exit(1);

});


