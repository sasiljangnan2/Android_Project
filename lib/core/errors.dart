import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => '이미 가입한 이메일이에요. 로그인해 주세요.',
      'invalid-email' => '이메일 형식을 확인해 주세요.',
      'weak-password' => '비밀번호가 너무 쉬워요. 6자 이상으로 입력해 주세요.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => '이메일 또는 비밀번호를 확인해 주세요.',
      'too-many-requests' => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
      'network-request-failed' => '네트워크에 연결한 후 다시 시도해 주세요.',
      'operation-not-allowed' => '이메일 회원가입 설정을 확인해 주세요.',
      'user-disabled' => '이용이 중지된 계정이에요.',
      _ => '계정 처리를 완료하지 못했어요. 연결 상태를 확인해 주세요.',
    };
  }
  if (error is FirebaseFunctionsException) {
    return error.message ?? '처리하지 못했어요. 최신 상태를 다시 확인해 주세요.';
  }
  if (error is TimeoutException) return '응답을 확인하지 못했어요. 연결 후 결과를 다시 확인해 주세요.';
  if (error is StateError) return error.message.toString();
  return '연결을 확인한 후 다시 시도해 주세요.';
}

bool isMissing(Object error) =>
    error is FirebaseFunctionsException && error.code == 'not-found' ||
    error is StateError && error.message.toString().contains('찾을 수 없');
bool isDefiniteRejection(Object error) =>
    error is StateError ||
    error is FirebaseFunctionsException &&
        const {
          'invalid-argument',
          'failed-precondition',
          'permission-denied',
          'unauthenticated',
          'not-found',
          'already-exists',
        }.contains(error.code);
