import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/theme.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.repository, required this.id});
  final RecruitmentRepository repository;
  final String id;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController(), _scroll = ScrollController();
  Timer? _timer;
  Recruitment? _item;
  List<ChatMessage> _messages = [];
  String? _loadError, _sendError, _pendingId, _pendingText;
  bool _loading = true, _fetching = false, _sending = false, _allowed = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    try {
      final item = await widget.repository
          .get(widget.id)
          .timeout(const Duration(seconds: 5));
      if (item.status != 'matched' ||
          !item.members.contains(widget.repository.uid)) {
        throw StateError('매칭된 참여자만 채팅할 수 있어요.');
      }
      final messages = await widget.repository
          .messages(widget.id)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final changed =
          _messages.length != messages.length ||
          (_messages.isNotEmpty &&
              messages.isNotEmpty &&
              _messages.last.at != messages.last.at);
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 100;
      setState(() {
        _item = item;
        _messages = messages;
        _allowed = true;
        _loadError = null;
      });
      if (changed && nearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allowed = false;
          _loadError = friendlyError(e);
        });
      }
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending || !_allowed) return;
    final text = _pendingText ?? _input.text.trim();
    if (text.isEmpty || text.length > 1000) return;
    _pendingId ??= const Uuid().v4();
    _pendingText ??= text;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await widget.repository
          .send(widget.id, _pendingId!, _pendingText!)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _pendingId = null;
        _pendingText = null;
        _input.clear();
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _sendError =
              '${friendlyError(e)}\n작성한 메시지는 유지돼요. 같은 메시지로 다시 전송할 수 있어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('참여자 채팅'),
      actions: [
        IconButton(
          tooltip: '참여자 목록',
          onPressed: _allowed && _item != null
              ? () => showParticipants(context, _item!, widget.repository.uid)
              : null,
          icon: const Icon(Icons.people_outline),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            if (_item != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ProductPhoto(
                        repository: widget.repository,
                        path: _item!.photo,
                        height: 52,
                        width: 52,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item!.product,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '매칭 완료 · ${_item!.members.length}명 · 예상 ${won(_item!.estimate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Notice('$_loadError\n연결과 참여 권한을 다시 확인해 주세요.', error: true),
                    TextButton.icon(
                      onPressed: _fetching ? null : () => _load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 연결하기'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: BusyLabel('채팅 불러오는 중'))
                  : _messages.isEmpty
                  ? const SingleChildScrollView(
                      child: EmptyState(
                        title: '첫 인사를 나눠보세요',
                        message: '수령 시간과 장소를 함께 정해요.\n서로 배려하는 대화를 부탁드려요.',
                        icon: Icons.chat_bubble_outline,
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index],
                            self = m.uid == widget.repository.uid;
                        return Align(
                          alignment: self
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .76,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: self
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!self)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        m.uid == _item?.ownerId
                                            ? '모집자'
                                            : '참여 이웃',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: self
                                          ? AppColors.lime
                                          : Theme.of(context)
                                                .colorScheme
                                                .surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      m.text,
                                      style: TextStyle(
                                        color: self
                                            ? AppColors.ink
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    localTime(m.at),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Notice(_sendError!, error: true),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('chat-input'),
                      controller: _input,
                      enabled: _allowed && !_sending && _pendingId == null,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '수령 약속을 이야기해요',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('chat-send'),
                      onPressed:
                          !_allowed ||
                              _sending ||
                              (_pendingText ?? _input.text.trim()).isEmpty
                          ? null
                          : _send,
                      child: _sending
                          ? const BusyLabel('전송 결과 확인 중')
                          : Text(
                              _pendingId == null ? '메시지 보내기' : '같은 메시지 다시 전송',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
