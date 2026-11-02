import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';

import '../domain/recruitment.dart';
import 'repository.dart';

class FirebaseRepository implements RecruitmentRepository {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
  @override
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  Future<dynamic> _call(String name, Map<String, dynamic> data) async =>
      (await _functions
              .httpsCallable(
                name,
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 5),
                ),
              )
              .call<dynamic>(data))
          .data;
  Recruitment _parse(dynamic j) =>
      Recruitment.fromJson(Map<String, dynamic>.from(j as Map));
  @override
  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
  }) async {
    if (register) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();
  @override
  Future<List<Recruitment>> list(LatLng center, int radius) async =>
      (await _call('listRecruitments', {
        'lat': center.latitude,
        'lng': center.longitude,
        'radius': radius,
      }) as List).map(_parse).toList();
  @override
  Future<Recruitment> get(String id) async =>
      _parse(await _call('getRecruitment', {'id': id}));
  @override
  Future<Recruitment> create(
    String requestId,
    Map<String, dynamic> data,
  ) async => _parse(
    await _call('createRecruitment', {...data, 'requestId': requestId}),
  );
  @override
  Future<Recruitment> participate(String id, {bool cancel = false}) async =>
      _parse(
        await _call(cancel ? 'cancelParticipation' : 'joinRecruitment', {
          'id': id,
        }),
      );
  @override
  Future<String> upload(String requestId, Uint8List bytes) async {
    final path = 'recruitmentPhotos/$uid/$requestId';
    final ref = FirebaseStorage.instance.ref(path);
    try {
      await ref.getMetadata().timeout(const Duration(seconds: 5));
      return path;
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
    await ref
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
        .timeout(const Duration(seconds: 5));
    return path;
  }

  @override
  Future<List<ChatMessage>> messages(String id) async =>
      (await _call('listMessages', {'id': id}) as List)
          .map(
            (dynamic m) => ChatMessage(
              m['uid'] as String,
              m['text'] as String,
              DateTime.parse(m['at'] as String),
            ),
          )
          .toList();
  @override
  Future<void> send(String id, String requestId, String text) async {
    await _call('sendMessage', {
      'id': id,
      'requestId': requestId,
      'text': text,
    });
  }
}
