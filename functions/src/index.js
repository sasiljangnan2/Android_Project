'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const domain = require('./domain');
initializeApp();
const db = getFirestore();
const collection = db.collection('recruitments');
function id(value) {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(value)) domain.fail('잘못된 요청 ID입니다.', 'invalid-argument');
  return value;
}
function callable(fn) {
  return onCall({region: 'asia-northeast3', timeoutSeconds: 30}, async request => {
    if (!request.auth) throw new HttpsError('unauthenticated', '로그인이 필요합니다.');
    try { return await fn(request.data || {}, request.auth.uid); }
    catch (e) {
      if (e instanceof domain.DomainError) throw new HttpsError(e.code, e.message);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError('internal', '처리 결과를 조회한 뒤 다시 시도하세요.');
    }
  });
}
async function fresh(ref) {
  return db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if (!doc.exists) domain.fail('모집을 찾을 수 없습니다.', 'not-found');
    const before = doc.data();
    const after = domain.expire(before, Date.now());
    if (before.status !== after.status) tx.update(ref, {status: after.status});
    return {id: doc.id, ...after};
  });
}
exports.createRecruitment = callable(async (d, uid) => {
  const requestId = id(d.requestId);
  const ref = collection.doc(`${uid}_${requestId}`);
  const existing = await ref.get();
  if (existing.exists) return fresh(ref);
  const value = domain.validateCreate(d, domain.gateFromEnv(process.env), uid, Date.now());
  try {
    const [meta] = await getStorage().bucket().file(value.photo).getMetadata();
    if (Number(meta.size) > 5 * 1024 * 1024 || !meta.contentType?.startsWith('image/')) domain.fail('유효한 사진이 필요합니다.');
  } catch (e) {
    if (e instanceof domain.DomainError) throw e;
    domain.fail('사진 업로드를 확인하고 다시 시도하세요.');
  }
  return db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if (doc.exists) return {id: doc.id, ...doc.data()};
    if (Date.parse(value.deadline) <= Date.now()) domain.fail('미래의 마감을 선택하세요.');
    const record = {...value, ownerId: uid, members: [uid], status: 'open', createdAt: new Date().toISOString()};
    tx.create(ref, record);
    return {id: ref.id, ...record};
  });
});
exports.getRecruitment = callable(async d => fresh(collection.doc(id(d.id))));
exports.listRecruitments = callable(async d => {
  if (!domain.coordinate(d.lat, d.lng) || ![500, 1000, 2000].includes(d.radius)) domain.fail('검색 조건을 확인하세요.', 'invalid-argument');
  const gate = domain.gateFromEnv(process.env);
  // Initial single-campus MVP: bounded service area. Scale with geohash + pagination.
  const snap = await collection.get();
  const selected = snap.docs.filter(doc => domain.distance(gate, doc.data()) <= 2000 && domain.distance(d, doc.data()) <= d.radius);
  const result = [];
  for (let start = 0; start < selected.length; start += 20) {
    result.push(...await Promise.all(selected.slice(start, start + 20).map(doc => fresh(doc.ref))));
  }
  return result.sort((a, b) => domain.distance(d, a) - domain.distance(d, b));
});
function participation(cancel) {
  return callable(async (d, uid) => {
    const ref = collection.doc(id(d.id));
    const result = await db.runTransaction(async tx => {
      const doc = await tx.get(ref);
      if (!doc.exists) domain.fail('모집을 찾을 수 없습니다.', 'not-found');
      const before = doc.data();
      const current = domain.expire(before, Date.now());
      if (current.status !== before.status) {
        tx.update(ref, {status: current.status});
        return {expired: true};
      }
      const after = domain.participate(current, uid, cancel, Date.now());
      tx.update(ref, {members: after.members, status: after.status});
      return {id: doc.id, ...after};
    });
    if (result.expired) domain.fail('마감되어 모집이 취소되었습니다. 다시 조회하세요.');
    return result;
  });
}
exports.joinRecruitment = participation(false);
exports.cancelParticipation = participation(true);
exports.listMessages = callable(async (d, uid) => {
  const ref = collection.doc(id(d.id));
  domain.authorizeChat(await fresh(ref), uid);
  const snap = await ref.collection('messages').orderBy('at', 'desc').limit(100).get();
  return snap.docs.map(doc => doc.data()).reverse();
});
exports.sendMessage = callable(async (d, uid) => {
  const ref = collection.doc(id(d.id));
  if (typeof d.text !== 'string' || !d.text.trim() || d.text.length > 1000) domain.fail('메시지는 1~1000자입니다.', 'invalid-argument');
  const messageRef = ref.collection('messages').doc(`${uid}_${id(d.requestId)}`);
  return db.runTransaction(async tx => {
    const [doc, message] = await Promise.all([tx.get(ref), tx.get(messageRef)]);
    if (!doc.exists) domain.fail('모집을 찾을 수 없습니다.', 'not-found');
    domain.authorizeChat(doc.data(), uid);
    if (!message.exists) tx.create(messageRef, {uid, text: d.text.trim(), at: new Date().toISOString()});
    return {ok: true};
  });
});
exports.expireRecruitments = onSchedule({schedule: 'every 1 minutes', region: 'asia-northeast3'}, async () => {
  // Read paths also enforce deadlines, so a scheduler delay never approves a late join.
  const snap = await collection.where('status', '==', 'open').where('deadline', '<=', new Date().toISOString()).get();
  for (const doc of snap.docs) await fresh(doc.ref);
});
