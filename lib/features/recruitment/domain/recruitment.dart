import 'package:latlong2/latlong.dart';

class Recruitment {
  const Recruitment({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.estimate,
    required this.target,
    required this.ownerId,
    required this.members,
    required this.deadline,
    required this.place,
    required this.point,
    required this.photo,
    required this.status,
  });
  final String id, product, quantity, ownerId, place, photo, status;
  final int price, estimate, target;
  final List<String> members;
  final DateTime deadline;
  final LatLng point;
  String get label => status == 'matched'
      ? '매칭 완료'
      : status == 'cancelled'
      ? '모집 취소'
      : '모집 중';
  factory Recruitment.fromJson(Map<String, dynamic> j) => Recruitment(
    id: j['id'] as String,
    product: j['product'] as String,
    quantity: j['quantity'] as String,
    price: j['price'] as int,
    estimate: j['estimate'] as int,
    target: j['target'] as int,
    ownerId: j['ownerId'] as String,
    members: List<String>.from(j['members'] as List),
    deadline: DateTime.parse(j['deadline'] as String),
    place: j['place'] as String,
    point: LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
    photo: j['photo'] as String,
    status: j['status'] as String,
  );
}

class ChatMessage {
  const ChatMessage(this.uid, this.text, this.at);
  final String uid, text;
  final DateTime at;
}
