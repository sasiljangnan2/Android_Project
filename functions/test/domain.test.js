const {test} = require('node:test');
const assert = require('node:assert/strict');
const d = require('../src/domain');
const now = Date.now();
const gate = {lat: 37.5, lng: 127};
const make = () => ({ownerId: 'owner', members: ['owner'], target: 2, status: 'open', deadline: new Date(now + 60000).toISOString()});
test('거리 0, 서비스 경계 안·밖', () => {
  assert.equal(d.distance(gate, gate), 0);
  assert.ok(d.distance(gate, {lat: 37.5179, lng: 127}) < 2000);
  assert.ok(d.distance(gate, {lat: 37.5181, lng: 127}) > 2000);
});
test('정문 좌표 누락·NaN·범위 초과 차단', () => {
  for (const env of [{}, {GATE_LAT: '', GATE_LNG: ''}, {GATE_LAT: 'NaN', GATE_LNG: '127'}, {GATE_LAT: '91', GATE_LNG: '127'}]) assert.throws(() => d.gateFromEnv(env));
});
test('마지막 자리 매칭·다음 신청 차단·동일 계정 세 번 재시도', () => {
  const matched = d.participate(make(), 'alice', false, now);
  assert.equal(matched.status, 'matched');
  for (let i = 0; i < 3; i++) assert.deepEqual(d.participate(matched, 'alice', false, now), matched);
  assert.throws(() => d.participate(matched, 'bob', false, now));
  assert.throws(() => d.participate(matched, 'alice', true, now));
});
test('모집자 취소 거부·모집 중 참여자 취소·중복 취소', () => {
  const r = {...make(), target: 3};
  assert.throws(() => d.participate(r, 'owner', true, now));
  const joined = d.participate(r, 'alice', false, now);
  const cancelled = d.participate(joined, 'alice', true, now);
  assert.deepEqual(cancelled.members, ['owner']);
  assert.deepEqual(d.participate(cancelled, 'alice', true, now), cancelled);
});
test('마감 경계에서 취소·매칭은 마감 후에도 유지', () => {
  const r = {...make(), deadline: new Date(now).toISOString()};
  assert.equal(d.expire(r, now).status, 'cancelled');
  assert.throws(() => d.participate(r, 'alice', false, now));
  assert.equal(d.expire({...r, status: 'matched'}, now).status, 'matched');
});
test('매칭된 참여자만 채팅', () => {
  assert.throws(() => d.authorizeChat(make(), 'owner'));
  const matched = d.participate(make(), 'alice', false, now);
  assert.doesNotThrow(() => d.authorizeChat(matched, 'alice'));
  assert.throws(() => d.authorizeChat(matched, 'other'));
});
test('등록 필드·서비스 범위·미래 마감·본인 사진 검증', () => {
  const valid = {...gate, product: '쌀', quantity: '10kg', place: '정문', price: 30000, estimate: 10000, target: 3,
    deadline: new Date(now + 60000).toISOString(), requestId: 'request', photo: 'recruitmentPhotos/owner/request'};
  assert.equal(d.validateCreate(valid, gate, 'owner', now).estimate, 10000);
  for (const change of [{product: ''}, {target: 1}, {price: -1}, {estimate: 1.5}, {lat: 38}, {deadline: new Date(now).toISOString()}, {photo: 'recruitmentPhotos/other/request'}]) {
    assert.throws(() => d.validateCreate({...valid, ...change}, gate, 'owner', now));
  }
});
