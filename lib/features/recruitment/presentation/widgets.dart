import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.lime,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Icon(
      Icons.shopping_basket_outlined,
      size: size * .58,
      color: AppColors.ink,
    ),
  );
}

class BusyLabel extends StatelessWidget {
  const BusyLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: WrapAlignment.center,
    children: [
      const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      Text(text),
    ],
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error
            ? c.errorContainer
            : c.secondaryContainer.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.info_outline,
            size: 18,
            color: error ? c.error : c.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: error ? c.onErrorContainer : c.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .6),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.item, {super.key});
  final Recruitment item;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: item.status == 'open'
            ? AppColors.lime.withValues(alpha: .5)
            : c.secondaryContainer,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${item.label} · ${item.members.length}/${item.target}명',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c.onSurface,
        ),
      ),
    );
  }
}

class ProductPhoto extends StatefulWidget {
  const ProductPhoto({
    super.key,
    required this.repository,
    required this.path,
    this.height = 92,
    this.width,
  });
  final RecruitmentRepository repository;
  final String path;
  final double height;
  final double? width;
  @override
  State<ProductPhoto> createState() => _ProductPhotoState();
}

class _ProductPhotoState extends State<ProductPhoto> {
  Future<Uint8List?>? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProductPhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.repository != widget.repository) _load();
  }

  void _load() {
    if (!widget.path.startsWith('asset:') && widget.path.isNotEmpty) {
      _bytes = widget.repository.photo(widget.path);
    }
  }

  Widget _fallback({bool retry = false}) => Container(
    color: Theme.of(context).colorScheme.secondaryContainer
        .withValues(alpha: .45),
    child: Center(
      child: retry
          ? IconButton(
              tooltip: '사진 다시 불러오기',
              onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh),
            )
          : const Icon(Icons.shopping_basket_outlined, size: 32),
    ),
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      height: widget.height,
      width: widget.width,
      child: widget.path.startsWith('asset:')
          ? Image.asset(
              widget.path.substring(6),
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => _fallback(),
            )
          : _bytes == null
          ? _fallback()
          : FutureBuilder<Uint8List?>(
              future: _bytes,
              builder: (context, s) => s.connectionState != ConnectionState.done
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : s.hasError || s.data == null
                  ? _fallback(retry: true)
                  : Image.memory(
                      s.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => _fallback(retry: true),
                    ),
            ),
    ),
  );
}

class RecruitmentCard extends StatelessWidget {
  const RecruitmentCard({
    super.key,
    required this.repository,
    required this.item,
    required this.distance,
    this.onTap,
  });
  final RecruitmentRepository repository;
  final Recruitment item;
  final int distance;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusTag(item),
            Text(
              '직선 ${distance}m',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.product,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.quantity,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '예상 1인 ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
              TextSpan(
                text: won(item.estimate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: '${item.product} 상세 보기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (large) ...[
                  ProductPhoto(
                    repository: repository,
                    path: item.photo,
                    height: 140,
                  ),
                  const SizedBox(height: 12),
                  summary,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductPhoto(
                        repository: repository,
                        path: item.photo,
                        height: 112,
                        width: 96,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: summary),
                    ],
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      '함께 ${item.members.length} / ${item.target}명',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${localTime(item.deadline)} 마감',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.members.length / item.target,
                    minHeight: 4,
                    color: item.status == 'cancelled'
                        ? Theme.of(context).colorScheme.outline
                        : AppColors.lime,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: .4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.shopping_basket_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer
                .withValues(alpha: .5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

Future<T?> appSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );

Future<void> showParticipants(
  BuildContext context,
  Recruitment r,
  String? uid,
) => appSheet<void>(
  context,
  Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '함께하는 이웃 ${r.members.length}명',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('모집자를 포함한 참여 인원이에요.'),
      const SizedBox(height: 16),
      for (var i = 0; i < r.members.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.lime.withValues(alpha: .4),
            child: Text(r.members[i] == uid ? '나' : '${i + 1}'),
          ),
          title: Text(
            r.members[i] == uid
                ? '나'
                : r.members[i] == r.ownerId
                ? '모집자'
                : '이웃 ${i + 1}',
          ),
          subtitle: Text(
            r.members[i] == r.ownerId ? '이 모집을 열었어요' : '함께 구매할 이웃이에요',
          ),
        ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('확인'),
      ),
    ],
  ),
);
