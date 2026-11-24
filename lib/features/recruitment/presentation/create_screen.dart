import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/theme.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'location_screen.dart';
import 'widgets.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _forms = List.generate(3, (_) => GlobalKey<FormState>());
  final _product = TextEditingController(),
      _quantity = TextEditingController(),
      _price = TextEditingController(),
      _estimate = TextEditingController(),
      _target = TextEditingController(text: '3'),
      _place = TextEditingController();
  final _scroll = ScrollController();
  int _step = 0;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  LatLng? _point;
  Uint8List? _photo;
  String _requestId = const Uuid().v4();
  String? _uploaded, _error;
  bool _busy = false, _uncertain = false, _allowPop = false;
  @override
  void initState() {
    super.initState();
    for (final c in [_product, _quantity, _price, _estimate, _target, _place]) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_product, _quantity, _price, _estimate, _target, _place]) {
      c.removeListener(_changed);
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  bool get _ready => switch (_step) {
    0 =>
      _photo != null &&
          [
            _product,
            _quantity,
            _price,
            _estimate,
          ].every((c) => c.text.trim().isNotEmpty),
    1 => _target.text.trim().isNotEmpty,
    _ => _place.text.trim().isNotEmpty && _point != null,
  };
  bool get _hasDraft =>
      _photo != null ||
      [
        _product,
        _quantity,
        _price,
        _estimate,
        _place,
      ].any((c) => c.text.isNotEmpty);
  Future<void> _back({bool close = false}) async {
    if (_busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록 결과를 확인하고 있어요. 잠시 기다려 주세요.')),
      );
      return;
    }
    if (_step > 0 && !_uncertain && !close) {
      setState(() => _step--);
      _scroll.jumpTo(0);
      return;
    }
    if (!_hasDraft) {
      _close();
      return;
    }
    final discard = await appSheet<bool>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '작성을 그만둘까요?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            _uncertain
                ? '응답을 확인하지 못했어요. 이미 등록되었을 수 있으니 내 모집에서 확인해 주세요.'
                : '나가면 작성 중인 내용이 사라져요.',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 작성하기'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_uncertain ? '나가기' : '작성 그만두기'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _close();
  }

  void _close([Recruitment? result]) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('사진은 5MB 이하로 선택해 주세요.');
      }
      if (bytes.isEmpty) throw StateError('읽을 수 없는 사진이에요. 다른 사진을 선택해 주세요.');
      // Decode before accepting bytes so an unsupported image never reaches preview/upload.
      final data = await decodeImageFromList(bytes);
      data.dispose();
      if (mounted) {
        setState(() {
          _photo = bytes;
          _uploaded = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _choosePoint() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(initial: _point ?? AppConfig.gate),
      ),
    );
    if (point != null && mounted) setState(() => _point = point);
  }

  Future<void> _chooseDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time != null && mounted) {
      setState(
        () => _deadline = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  void _next() {
    if (!_forms[_step].currentState!.validate()) return;
    if (_step == 1 && !_deadline.isAfter(DateTime.now())) {
      setState(() => _error = '미래의 마감 시각을 선택해 주세요.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _step++;
      _error = null;
    });
    _scroll.jumpTo(0);
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!_uncertain && !_forms[_step].currentState!.validate()) return;
    if (_photo == null || _point == null) return;
    if (!_uncertain && !_deadline.isAfter(DateTime.now())) {
      setState(() {
        _step = 1;
        _error = '마감 시각이 지났어요. 미래의 시각으로 변경해 주세요.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Recruitment? existing;
      if (_uncertain) {
        try {
          existing = await widget.repository
              .get('${widget.repository.uid}_$_requestId')
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          if (!isMissing(e)) rethrow;
        }
      }
      if (existing == null) {
        _uploaded ??= await widget.repository
            .upload(_requestId, _photo!)
            .timeout(const Duration(seconds: 5));
      }
      final result =
          existing ??
          await widget.repository
              .create(_requestId, {
                'product': _product.text.trim(),
                'quantity': _quantity.text.trim(),
                'price': int.parse(_price.text),
                'estimate': int.parse(_estimate.text),
                'target': int.parse(_target.text),
                'place': _place.text.trim(),
                'lat': _point!.latitude,
                'lng': _point!.longitude,
                'deadline': _deadline.toUtc().toIso8601String(),
                'photo': _uploaded,
              })
              .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      await appSheet<void>(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.lime,
                child: Icon(Icons.check, color: AppColors.ink, size: 34),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '모집을 등록했어요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${result.product}\n이제 함께할 이웃을 기다려요.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('내가 연 모집 보기'),
            ),
          ],
        ),
      );
      if (mounted) _close(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${friendlyError(e)}\n입력한 내용은 유지돼요.';
          _uncertain = !isDefiniteRejection(e);
          if (_uncertain) {
            _error = '$_error\n같은 요청으로 등록 결과를 확인해 주세요.';
          } else {
            _requestId = const Uuid().v4();
            _uploaded = null;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    int? min,
    int? max,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: c,
      enabled: !_busy && !_uncertain,
      keyboardType: min == null ? TextInputType.text : TextInputType.number,
      inputFormatters: min == null
          ? null
          : [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      maxLength: min == null ? 120 : 9,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '필수 항목을 입력해 주세요.';
        final n = int.tryParse(v);
        if (min != null && (n == null || n < min || (max != null && n > max))) {
          return max == null
              ? '$min 이상의 정수를 입력해 주세요.'
              : '$min~$max 사이의 정수를 입력해 주세요.';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '이전 단계',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('모집 만들기'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _back(close: true),
            child: const Text('닫기'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= _step
                                    ? AppColors.ink
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${i + 1}. ${['제품', '조건', '장소'][i]}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == _step
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                ['어떤 제품을 나눌까요?', '함께할 조건을 정해요', '어디서 만날까요?'][_step],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                [
                  '필요한 만큼 나눌 제품을 알려주세요.',
                  '모집자도 인원에 포함돼요.',
                  '모두가 찾기 쉬운 수령 장소를 정해요.',
                ][_step],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              Form(
                key: _forms[_step],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 0) ...[
                      if (_photo == null)
                        OutlinedButton(
                          onPressed: _busy || _uncertain ? null : _pickPhoto,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                ),
                                SizedBox(height: 12),
                                Text('제품 사진 추가'),
                                SizedBox(height: 6),
                                Text(
                                  '필수 · 5MB 이하',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _photo!,
                                height: 190,
                                fit: BoxFit.cover,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _busy || _uncertain
                                  ? null
                                  : _pickPhoto,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('사진 변경'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _field(_product, '제품명', '예: 달걀 30구 같이 나눠요'),
                      _field(_quantity, '대용량 수량', '예: 30구 · 1인 약 10구'),
                      _field(_price, '전체 제품 가격 (원)', '예: 9900', min: 1),
                      _field(_estimate, '예상 1인 비용 (원)', '예: 3300', min: 1),
                      const Notice(
                        '예상 비용은 직접 입력하는 참고 금액이에요. 자동으로 계산하거나 정산하지 않아요.',
                      ),
                    ],
                    if (_step == 1) ...[
                      _field(
                        _target,
                        '목표 인원 (모집자 포함)',
                        '2~100명',
                        min: 2,
                        max: 100,
                      ),
                      const Text(
                        '모집 마감',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy || _uncertain ? null : _chooseDeadline,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(localTime(_deadline)),
                      ),
                      const SizedBox(height: 18),
                      const Notice(
                        '목표 인원이 모이면 매칭이 완료돼요. 마감까지 인원이 모이지 않으면 모집이 취소돼요. 매칭 후에는 참여를 취소할 수 없어요.',
                      ),
                    ],
                    if (_step == 2) ...[
                      _field(_place, '수령 장소 이름', '예: 정문 앞 벤치'),
                      OutlinedButton.icon(
                        onPressed: _busy || _uncertain ? null : _choosePoint,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          _point == null
                              ? '지도에서 장소 선택'
                              : '선택 완료 · 정문에서 ${meters(AppConfig.gate, _point!).round()}m',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Notice('정문에서 직선거리 2km 이내의 장소만 선택할 수 있어요.'),
                      const SizedBox(height: 24),
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '등록 전 확인',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _product.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_quantity.text),
                            const SizedBox(height: 12),
                            Text(
                              '전체 ${won(int.tryParse(_price.text) ?? 0)}\n예상 1인 ${won(int.tryParse(_estimate.text) ?? 0)}\n목표 ${_target.text}명 · 모집자 포함\n마감 ${localTime(_deadline)}',
                              style: const TextStyle(height: 1.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Notice(_error!, error: true),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: FilledButton(
                onPressed: _busy || (!_ready && !_uncertain)
                    ? null
                    : (_step < 2 && !_uncertain ? _next : _save),
                child: _busy
                    ? const BusyLabel('등록 결과 확인 중')
                    : Text(
                        _uncertain
                            ? '같은 요청으로 결과 확인하기'
                            : _step < 2
                            ? '다음 단계  →'
                            : '모집 등록하기',
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
