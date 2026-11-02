import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../data/repository.dart';
import 'detail_screen.dart';
import 'home_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final form = GlobalKey<FormState>();
  final product = TextEditingController(),
      quantity = TextEditingController(),
      price = TextEditingController(),
      estimate = TextEditingController(),
      target = TextEditingController(text: '3'),
      place = TextEditingController();
  final requestId = DateTime.now().microsecondsSinceEpoch.toString();
  LatLng? point;
  Uint8List? photo;
  String? uploaded, error;
  DateTime deadline = DateTime.now().add(const Duration(days: 1));
  bool busy = false, uncertain = false;
  @override
  void dispose() {
    for (final c in [product, quantity, price, estimate, target, place]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('사진은 5MB 이하로 선택하세요.');
      }
      if (mounted) {
        setState(() {
          photo = bytes;
          uploaded = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    }
  }

  Future<void> choosePoint() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(initial: point ?? AppConfig.gate),
      ),
    );
    if (result != null && mounted) setState(() => point = result);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (photo == null || point == null) {
      setState(() => error = '사진과 지도상의 수령 장소를 선택하세요.');
      return;
    }
    if (!deadline.isAfter(DateTime.now())) {
      setState(() => error = '미래의 마감 시각을 선택하세요.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      uploaded ??= await widget.repository.upload(requestId, photo!);
      final r = await widget.repository
          .create(requestId, {
            'product': product.text.trim(),
            'quantity': quantity.text.trim(),
            'price': int.parse(price.text),
            'estimate': int.parse(estimate.text),
            'target': int.parse(target.text),
            'place': place.text.trim(),
            'lat': point!.latitude,
            'lng': point!.longitude,
            'deadline': deadline.toUtc().toIso8601String(),
            'photo': uploaded,
          })
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(repository: widget.repository, id: r.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '${friendlyError(e)}\n입력은 유지됩니다. 같은 요청으로 결과를 확인·재시도하세요.';
          uncertain = true;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(TextEditingController c, String label, {int? min}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      enabled: !busy && !uncertain,
      keyboardType: min == null ? TextInputType.text : TextInputType.number,
      maxLength: min == null ? 120 : 9,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '필수 항목입니다.';
        if (min != null && (int.tryParse(v) == null || int.parse(v) < min)) {
          return '$min 이상의 정수를 입력하세요.';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('공동구매 모집 만들기')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '함께 구매할 제품을 알려 주세요.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (photo != null)
                Image.memory(photo!, height: 160, fit: BoxFit.cover),
              OutlinedButton.icon(
                onPressed: busy || uncertain ? null : pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('제품 사진 선택 (필수, 5MB 이하)'),
              ),
              const SizedBox(height: 12),
              field(product, '제품명'),
              field(quantity, '대용량 수량 (예: 210g × 24개)'),
              field(price, '전체 가격 (원)', min: 1),
              field(estimate, '예상 1인 비용 (직접 입력, 원)', min: 1),
              field(target, '모집자 포함 목표 인원', min: 2),
              field(place, '수령 장소 이름'),
              const Text('예상 비용은 참고 금액이며 자동 계산·정산하지 않습니다.'),
              OutlinedButton.icon(
                onPressed: busy || uncertain ? null : choosePoint,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  point == null
                      ? '지도에서 수령 장소 선택'
                      : '선택한 장소 · 정문에서 ${meters(AppConfig.gate, point!).round()}m',
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy || uncertain
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(deadline),
                        );
                        if (time != null && mounted) {
                          setState(
                            () => deadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.schedule),
                label: Text('마감 ${localTime(deadline)}'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(uncertain ? '같은 요청 결과 확인·재시도' : '모집 등록'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.initial});
  final LatLng initial;
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late LatLng point = widget.initial;
  bool failed = false, loaded = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('수령 장소를 지도에서 선택')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('지도를 눌러 선택하세요. 정문 반경 2km 안에서만 등록할 수 있어요.'),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
              onTap: (_, p) => setState(() => point = p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hungrystudent.hungry_student',
                tileBuilder: (context, image, tile) {
                  if (tile.loadError && !failed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => failed = true);
                    });
                  }
                  if (tile.loadFinishedAt != null &&
                      !tile.loadError &&
                      !loaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => loaded = true);
                    });
                  }
                  return image;
                },
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: AppConfig.gate,
                    radius: 2000,
                    useRadiusInMeter: true,
                    color: Colors.green.withValues(alpha: 0.08),
                    borderColor: Colors.green,
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    child: const Icon(
                      Icons.location_pin,
                      size: 42,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '© OpenStreetMap contributors · openstreetmap.org/copyright',
          ),
        ),
        if (failed)
          const Text(
            '지도 일부를 불러오지 못했어요. 뒤로 간 후 다시 시도하세요.',
            style: TextStyle(color: Colors.red),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed:
                  !loaded || failed || meters(AppConfig.gate, point) > 2000
                  ? null
                  : () => Navigator.pop(context, point),
              child: Text(
                '이 장소 선택 · 정문에서 ${meters(AppConfig.gate, point).round()}m',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
