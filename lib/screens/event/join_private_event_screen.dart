import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';
import 'event_detail_screen.dart';

class JoinPrivateEventScreen extends StatefulWidget {
  @override
  _JoinPrivateEventScreenState createState() => _JoinPrivateEventScreenState();
}

class _JoinPrivateEventScreenState extends State<JoinPrivateEventScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _eventIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _eventIdController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライベートイベントに参加'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'イベントID'),
            Tab(text: 'QRコード'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventIdTab(),
          _buildQRCodeTab(),
        ],
      ),
    );
  }

  Widget _buildEventIdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'イベントIDで参加',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'イベント主催者から共有されたイベントIDを入力してください。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _eventIdController,
                    decoration: const InputDecoration(
                      labelText: 'イベントID',
                      hintText: 'abcd1234efgh5678',
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'パスワード（必要な場合）',
                      hintText: 'イベントパスワード',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinEventById,
                      child: _isLoading
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('確認中...'),
                        ],
                      )
                          : const Text('参加する'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QRコードをスキャン',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'イベント会場やチラシのQRコードをスキャンして参加してください。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: QRコードスキャン機能を実装
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QRコードスキャン機能は準備中です'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('QRコードをスキャン'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '位置情報で参加',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'イベント会場付近にいる場合、位置情報を使って自動的にイベントを見つけることができます。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _findNearbyEvents,
                      icon: const Icon(Icons.my_location),
                      label: const Text('近くのイベントを探す'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinEventById() async {
    final eventId = _eventIdController.text.trim();
    final password = _passwordController.text.trim();

    if (eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('イベントIDを入力してください'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // イベントを取得
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('イベントが見つかりません');
      }

      final event = EventModel.fromFirestore(eventDoc);

      // パブリックイベントの場合
      if (event.isPublic) {
        _navigateToEvent(eventId);
        return;
      }

      // プライベートイベントの場合、パスワードチェック
      if (event.password != null && event.password!.isNotEmpty) {
        if (password.isEmpty) {
          throw Exception('パスワードを入力してください');
        }
        if (event.password != password) {
          throw Exception('パスワードが正しくありません');
        }
      }

      // 位置情報チェック（必要な場合）
      if (event.requiresLocation) {
        final hasLocationPermission = await _checkLocationPermission();
        if (!hasLocationPermission) {
          throw Exception('位置情報の許可が必要です');
        }

        final isNearby = await _checkLocationDistance(event);
        if (!isNearby) {
          throw Exception('イベント会場に近づいてから参加してください');
        }
      }

      _navigateToEvent(eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('参加に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _findNearbyEvents() async {
    try {
      // 位置情報の許可をチェック
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('位置情報の許可が必要です'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // 現在位置を取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 近くのプライベートイベントを検索
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('isPublic', isEqualTo: false)
          .where('requiresLocation', isEqualTo: true)
          .get();

      final nearbyEvents = <EventModel>[];

      for (final doc in snapshot.docs) {
        final event = EventModel.fromFirestore(doc);
        if (event.latitude != null && event.longitude != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            event.latitude!,
            event.longitude!,
          );

          // 設定された半径内にある場合
          if (distance <= (event.locationRadius ?? 1000)) {
            nearbyEvents.add(event);
          }
        }
      }

      if (nearbyEvents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('近くにイベントが見つかりませんでした'),
          ),
        );
        return;
      }

      // 近くのイベント一覧を表示
      _showNearbyEventsDialog(nearbyEvents);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('位置情報の取得に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showNearbyEventsDialog(List<EventModel> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('近くのイベント'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.name),
                subtitle: Text(event.venue),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEvent(event.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    return status.isGranted;
  }

  Future<bool> _checkLocationDistance(EventModel event) async {
    if (event.latitude == null || event.longitude == null) {
      return true; // 位置情報が設定されていない場合はOK
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        event.latitude!,
        event.longitude!,
      );

      return distance <= (event.locationRadius ?? 1000);
    } catch (e) {
      return false;
    }
  }

  void _navigateToEvent(String eventId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventId: eventId),
      ),
    );
  }
}