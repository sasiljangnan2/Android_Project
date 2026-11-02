import 'package:latlong2/latlong.dart';

abstract final class AppConfig {
  static const live = bool.fromEnvironment('USE_FIREBASE');
  static const gateLat = String.fromEnvironment('GATE_LAT');
  static const gateLng = String.fromEnvironment('GATE_LNG');
  static const gateName = String.fromEnvironment(
    'GATE_NAME',
    defaultValue: '대학 정문',
  );
  static LatLng get gate {
    if (!live) return const LatLng(37.5665, 126.9780);
    final lat = double.tryParse(gateLat);
    final lng = double.tryParse(gateLng);
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      throw StateError('실제 대학 정문 좌표 GATE_LAT / GATE_LNG를 설정하세요.');
    }
    return LatLng(lat, lng);
  }
}

double meters(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);
String won(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
String localTime(DateTime d) =>
    '${d.toLocal().month}/${d.toLocal().day} ${d.toLocal().hour.toString().padLeft(2, '0')}:${d.toLocal().minute.toString().padLeft(2, '0')}';
