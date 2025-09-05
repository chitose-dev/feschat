import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'event_chat_screen.dart';
import 'event_info_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventModel? _event;
  bool _isLoading = true;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvent();
    _checkParticipation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (doc.exists) {
        setState(() {
          _event = EventModel.fromFirestore(doc);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkParticipation() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(user.uid)
          .get();

      setState(() {
        _isJoined = doc.exists;
      });
    }
  }

  Future<void> _joinEvent() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null || _event == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 参加者リストに追加
      final participantRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(user.uid);

      batch.set(participantRef, {
        'uid': user.uid,
        'nickname': user.nickname,
        'profileImageUrl': user.profileImageUrl,
        'joinedAt': Timestamp.now(),
      });

      // 参加者数を更新
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId);

      batch.update(eventRef, {
        'participantCount': FieldValue.increment(1),
      });

      await batch.commit();

      // システムメッセージを送信
      await EventChatScreen.sendSystemMessage(
        eventId: widget.eventId,
        content: '${user.nickname}さんがイベントに参加しました',
      );

      setState(() {
        _isJoined = true;
        if (_event != null) {
          _event = _event!.copyWith(
            participantCount: _event!.participantCount + 1,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('イベントに参加しました！'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('参加に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _leaveEvent() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null || _event == null) return;

    // 確認ダイアログを表示
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('イベントから退出'),
        content: const Text('本当にイベントから退出しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 参加者リストから削除
      final participantRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(user.uid);

      batch.delete(participantRef);

      // 参加者数を更新
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId);

      batch.update(eventRef, {
        'participantCount': FieldValue.increment(-1),
      });

      await batch.commit();

      // システムメッセージを送信
      await EventChatScreen.sendSystemMessage(
        eventId: widget.eventId,
        content: '${user.nickname}さんがイベントから退出しました',
      );

      setState(() {
        _isJoined = false;
        if (_event != null) {
          _event = _event!.copyWith(
            participantCount: _event!.participantCount - 1,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('イベントから退出しました'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退出に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('イベント'),
        ),
        body: const Center(
          child: Text('イベントが見つかりません'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _event!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                background: _event!.imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: _event!.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.festival,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // イベント情報カード
            Container(
              color: AppTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _event!.venue,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('yyyy年M月d日 (E)', 'ja').format(_event!.eventDate),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_event!.participantCount}人が参加中',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            if (!_isJoined)
                              ElevatedButton(
                                onPressed: _joinEvent,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('参加する'),
                              ),
                            if (_isJoined) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.successColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '参加中',
                                      style: TextStyle(
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _leaveEvent,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  side: const BorderSide(color: AppTheme.errorColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('退出'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    if (_event!.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _event!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    if (_event!.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _event!.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '#$tag',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // タブバー
            if (_isJoined)
              Container(
                color: AppTheme.surfaceColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(text: 'チャット'),
                    Tab(text: '情報共有'),
                  ],
                ),
              ),

            // タブビュー
            if (_isJoined)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    EventChatScreen(eventId: widget.eventId),
                    EventInfoScreen(eventId: widget.eventId),
                  ],
                ),
              ),

            // 参加していない場合のメッセージ
            if (!_isJoined)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'イベントに参加すると\nチャットや情報共有が利用できます',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _joinEvent,
                        child: const Text('参加する'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
