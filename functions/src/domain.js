'use strict';
class DomainError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
function fail(message, code = 'failed-precondition') { throw new DomainError(code, message); }
function coordinate(lat, lng) {
  return Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
}
function distance(a, b) {
  const rad = n => n * Math.PI / 180;
  const dlat = rad(b.lat - a.lat), dlng = rad(b.lng - a.lng);
  const h = Math.sin(dlat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dlng / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(Math.min(1, h)), Math.sqrt(Math.max(0, 1 - h)));
}
function gateFromEnv(env) {
  if (!env.GATE_LAT?.trim() || !env.GATE_LNG?.trim()) fail('대학 정문 좌표가 설정되지 않았습니다.');
  const gate = {lat: Number(env.GATE_LAT), lng: Number(env.GATE_LNG)};
  if (!coordinate(gate.lat, gate.lng)) fail('대학 정문 좌표를 확인하세요.');
  return gate;
}
function validateCreate(d, gate, uid, now) {
  for (const key of ['product', 'quantity', 'place']) {
    if (typeof d[key] !== 'string' || !d[key].trim() || d[key].length > 120) fail('제품·수량·장소를 확인하세요.', 'invalid-argument');
  }
  if (!Number.isSafeInteger(d.price) || d.price < 1 || !Number.isSafeInteger(d.estimate) || d.estimate < 1 ||
      !Number.isInteger(d.target) || d.target < 2 || d.target > 100) fail('금액 또는 인원(2~100명)을 확인하세요.', 'invalid-argument');
  if (!coordinate(d.lat, d.lng) || distance(gate, d) > 2000) fail('수령 장소는 정문 2km 이내여야 합니다.', 'invalid-argument');
  if (!Number.isFinite(Date.parse(d.deadline)) || Date.parse(d.deadline) <= now) fail('미래의 마감을 선택하세요.', 'invalid-argument');
  if (d.photo !== `recruitmentPhotos/${uid}/${d.requestId}`) fail('본인이 올린 사진이 필요합니다.', 'invalid-argument');
  return {product: d.product.trim(), quantity: d.quantity.trim(), place: d.place.trim(), price: d.price,
    estimate: d.estimate, target: d.target, lat: d.lat, lng: d.lng,
    deadline: new Date(d.deadline).toISOString(), photo: d.photo};
}
function expire(r, now) {
  return r.status === 'open' && Date.parse(r.deadline) <= now ? {...r, status: 'cancelled'} : r;
}
function participate(r, uid, cancel, now) {
  r = expire(r, now);
  // An approved join remains idempotent even if its response was lost at matching.
  if (!cancel && r.members.includes(uid)) return r;
  if (r.status !== 'open') fail('모집 중일 때만 참여·취소할 수 있습니다.');
  if (cancel && r.ownerId === uid) fail('모집자는 참여를 취소할 수 없습니다.');
  if (!cancel && r.members.length >= r.target) fail('모집 정원이 찼습니다.');
  const members = cancel ? r.members.filter(id => id !== uid) : [...r.members, uid];
  return {...r, members, status: members.length === r.target ? 'matched' : 'open'};
}
function authorizeChat(r, uid) {
  if (r.status !== 'matched' || !r.members.includes(uid)) fail('매칭된 참여자만 채팅할 수 있습니다.', 'permission-denied');
}
module.exports = {DomainError, fail, coordinate, distance, gateFromEnv, validateCreate, expire, participate, authorizeChat};
