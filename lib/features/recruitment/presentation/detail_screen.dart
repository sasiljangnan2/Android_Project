import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/config.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'home_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.repository, required this.id});
  final RecruitmentRepository repository;
  final String id;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Recruitment? item;
  bool busy = false, verified = false;
  String? error, photoUrl;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
      verified = false;
    });
    try {
      final r = await widget.repository
          .get(widget.id)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          item = r;
          verified = true;
        });
      }
      if (AppConfig.live) {
        try {
          final url = await FirebaseStorage.instance
              .ref(r.photo)
              .getDownloadURL()
              .timeout(const Duration(seconds: 5));
          if (mounted) setState(() => photoUrl = url);
        } catch (_) {
          /* Text fallback is shown when the photo cannot be fetched. */
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> act(bool cancel) async {
    setState(() {
      busy = true;
      verified = false;
      error = null;
    });
    try {
      final r = await widget.repository
          .participate(widget.id, cancel: cancel)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          item = r;
          verified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              '${friendlyError(e)}\n결과를 단정하지 않습니다. 새로고침으로 본인 참여 상태를 확인하세요.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = item;
    final member = r?.members.contains(widget.repository.uid) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('모집 상세'),
        actions: [
          IconButton(
            tooltip: '최신 상태 조회',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (r != null) ...[
                if (photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      photoUrl!,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text('사진을 불러오지 못했어요. 새로고침으로 재시도하세요.'),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xffe5eee3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 60),
                        Text('제품 사진 · 새로고침으로 다시 조회'),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  r.label,
                  style: const TextStyle(
                    color: Color(0xff32724b),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  r.product,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${r.quantity}\n전체 가격 ${won(r.price)}\n예상 1인 비용 ${won(r.estimate)}\n참여 ${r.members.length}/${r.target}명\n마감 ${localTime(r.deadline)}\n수령 ${r.place}',
                  style: const TextStyle(fontSize: 18, height: 1.8),
                ),
                const SizedBox(height: 16),
                const Text(
                  '예상 비용은 모집자가 직접 입력한 참고 금액입니다.\n매칭 완료는 모집 완료이며 구매 확정이 아닙니다.\n실제 구매·결제·분배·수령은 참여자가 직접 협의합니다.',
                ),
                const SizedBox(height: 24),
                if (r.status == 'open' && !member)
                  FilledButton(
                    onPressed: busy || !verified ? null : () => act(false),
                    child: const Text('함께 구매할 사람으로 참여하기'),
                  ),
                if (r.status == 'open' &&
                    member &&
                    r.ownerId != widget.repository.uid)
                  OutlinedButton(
                    onPressed: busy || !verified ? null : () => act(true),
                    child: const Text('참여 취소'),
                  ),
                if (member)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('내가 참여 중인 모집입니다.'),
                  ),
                if (r.status == 'matched' && member)
                  FilledButton.icon(
                    onPressed: busy || !verified
                        ? null
                        : () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                repository: widget.repository,
                                id: r.id,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('참여자 채팅'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.repository, required this.id});
  final RecruitmentRepository repository;
  final String id;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final text = TextEditingController();
  List<ChatMessage> messages = [];
  Timer? timer;
  bool busy = false, reading = false;
  String? error, pendingId, pendingText;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 4), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (reading) return;
    reading = true;
    try {
      final result = await widget.repository
          .messages(widget.id)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          messages = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      reading = false;
    }
  }

  Future<void> send() async {
    final value = pendingText ?? text.text.trim();
    if (value.isEmpty || value.length > 1000) return;
    pendingText = value;
    pendingId ??= DateTime.now().microsecondsSinceEpoch.toString();
    setState(() => busy = true);
    try {
      await widget.repository
          .send(widget.id, pendingId!, value)
          .timeout(const Duration(seconds: 5));
      pendingId = null;
      pendingText = null;
      text.clear();
      await load();
    } catch (e) {
      if (mounted) {
        setState(() => error = '${friendlyError(e)}\n재시도는 같은 메시지 ID로 처리됩니다.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('매칭 참여자 채팅'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        if (!AppConfig.live)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('시연 채팅 · 다른 기기와 연결되지 않습니다.'),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('구매와 수령 일정을 함께 정해 보세요.'))
              : ListView(
                  children: messages
                      .map(
                        (m) => ListTile(
                          leading: Icon(
                            m.uid == widget.repository.uid
                                ? Icons.person
                                : Icons.people,
                          ),
                          title: Text(m.text),
                          subtitle: Text(localTime(m.at)),
                        ),
                      )
                      .toList(),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    enabled: !busy && pendingId == null,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: '메시지'),
                  ),
                ),
                IconButton(
                  onPressed: busy || (error != null && pendingId == null)
                      ? null
                      : send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
