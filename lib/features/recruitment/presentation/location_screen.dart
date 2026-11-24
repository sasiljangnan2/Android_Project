import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import 'widgets.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.initial});
  final LatLng initial;
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late LatLng _point = widget.initial;
  bool _loaded = false, _failed = false;
  int _attempt = 0;
  void _tileState(bool failed, int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && attempt == _attempt) {
        setState(() {
          if (failed) {
            _failed = true;
          } else {
            _loaded = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final distance = meters(AppConfig.gate, _point).round();
    final attempt = _attempt;
    return Scaffold(
      appBar: AppBar(title: const Text('수령 장소 선택')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              '지도를 눌러 만날 장소를 선택해 주세요.\n정문 반경 2km 안에서만 등록할 수 있어요.',
              style: TextStyle(height: 1.5),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  key: ValueKey(_attempt),
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 16,
                    onTap: (_, p) => setState(() => _point = p),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hungrystudent.hungry_student',
                      tileBuilder: (context, image, tile) {
                        if (tile.loadError && !_failed) {
                          _tileState(true, attempt);
                        } else if (tile.loadFinishedAt != null &&
                            !tile.loadError &&
                            !_loaded) {
                          _tileState(false, attempt);
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
                          color: AppColors.ink.withValues(alpha: .08),
                          borderColor: AppColors.ink,
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: AppConfig.gate,
                          child: const Icon(Icons.school, color: AppColors.ink),
                        ),
                        Marker(
                          point: _point,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppColors.error,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_loaded && !_failed)
                  const Center(
                    child: SurfaceCard(child: BusyLabel('지도 불러오는 중')),
                  ),
                if (_failed)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SurfaceCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Notice(
                              '지도를 불러오지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
                              error: true,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _attempt++;
                                _loaded = false;
                                _failed = false;
                              }),
                              icon: const Icon(Icons.refresh),
                              label: const Text('지도 다시 불러오기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '© OpenStreetMap contributors · openstreetmap.org/copyright',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '정문에서 직선 ${distance}m',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (distance > 2000)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '서비스 지역을 벗어났어요. 2km 이내로 선택해 주세요.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: !_loaded || _failed || distance > 2000
                        ? null
                        : () => Navigator.pop(context, _point),
                    child: const Text('이 장소로 선택하기'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
