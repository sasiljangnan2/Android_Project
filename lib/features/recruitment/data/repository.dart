import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../domain/recruitment.dart';

abstract class RecruitmentRepository {
  bool get isDemo;
  String? get uid;
  String? get email;
  Stream<String?> get authChanges;
  Future<void> signIn(String email, String password, {bool register = false});
  Future<void> signOut();
  Future<List<Recruitment>> list(LatLng center, int radius);
  Future<Recruitment> get(String id);
  Future<Recruitment> create(String requestId, Map<String, dynamic> data);
  Future<Recruitment> participate(String id, {bool cancel = false});
  Future<String> upload(String requestId, Uint8List bytes);
  Future<Uint8List?> photo(String path);
  Future<List<ChatMessage>> messages(String id);
  Future<void> send(String id, String requestId, String text);
}
