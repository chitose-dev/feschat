import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/info_post_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class EventInfoScreen extends StatefulWidget {
  final String eventId;

  const EventInfoScreen({required this.eventId});

  @override
  _EventInfoScreenState createState() => _EventInfoScreenState();
}

class _EventInfoScreenState extends State<EventInfoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  PostCategory _selectedCategory = PostCategory.general;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 情報投稿リスト
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('info_posts')
                  .orderBy('isPinned', descending: true)
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('エラーが発生しました: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data?.docs
                    .map((doc) => InfoPostModel.fromFirestore(doc))
                    .toList() ??
                    [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'まだ情報投稿がありません',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '役立つ情報を投稿してみましょう！',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _buildInfoCard(post);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoCard(InfoPostModel post) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    final hasVotedHelpful = post.helpfulUsers.contains(currentUserId);
    final hasVotedNotHelpful = post.notHelpfulUsers.contains(currentUserId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                // カテゴリーアイコン
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(post.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(post.category),
                    size: 16,
                    color: _getCategoryColor(post.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        post.authorNickname,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin,
                          size: 12,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ピン',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 内容
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // 画像
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrls[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 120,
                          color: AppTheme.backgroundColor,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: AppTheme.backgroundColor,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // フッター
            Row(
              children: [
                Text(
                  DateFormat('M月d日 HH:mm').format(post.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
                const Spacer(),

                // 役に立った/役に立たなかったボタン
                Row(
                  children: [
                    InkWell(
                      onTap: () => _votePost(post, true),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasVotedHelpful
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasVotedHelpful
                                ? AppTheme.successColor
                                : AppTheme.textLight.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_up,
                              size: 14,
                              color: hasVotedHelpful
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.helpfulCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: hasVotedHelpful
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _votePost(post, false),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasVotedNotHelpful
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasVotedNotHelpful
                                ? AppTheme.errorColor
                                : AppTheme.textLight.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_down,
                              size: 14,
                              color: hasVotedNotHelpful
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.notHelpfulCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: hasVotedNotHelpful
                                    ? AppTheme.errorColor
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '情報を投稿',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // フォーム
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // カテゴリー選択
                      Text(
                        'カテゴリー',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PostCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getCategoryColor(category).withOpacity(0.1)
                                    : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _getCategoryColor(category)
                                      : AppTheme.textLight.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 16,
                                    color: isSelected
                                        ? _getCategoryColor(category)
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getCategoryName(category),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? _getCategoryColor(category)
                                          : AppTheme.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // タイトル
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'タイトル',
                          hintText: '投稿のタイトルを入力',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 内容
                      TextField(
                        controller: _contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '内容',
                          hintText: '詳細な情報を入力してください',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 投稿ボタン
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _createPost(context),
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
                        Text('投稿中...'),
                      ],
                    )
                        : const Text('投稿する'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルと内容を入力してください'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final postRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('info_posts')
          .doc();

      final post = InfoPostModel(
        id: postRef.id,
        eventId: widget.eventId,
        authorUid: user.uid,
        authorNickname: user.nickname,
        authorProfileImageUrl: user.profileImageUrl,
        title: title,
        content: content,
        category: _selectedCategory,
        timestamp: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await postRef.set(post.toFirestore());

      // フォームをクリア
      _titleController.clear();
      _contentController.clear();
      _selectedCategory = PostCategory.general;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('情報を投稿しました！'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('投稿に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _votePost(InfoPostModel post, bool isHelpful) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) return;

    try {
      final postRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('info_posts')
          .doc(post.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        final currentPost = InfoPostModel.fromFirestore(snapshot);

        List<String> newHelpfulUsers = List.from(currentPost.helpfulUsers);
        List<String> newNotHelpfulUsers = List.from(currentPost.notHelpfulUsers);

        if (isHelpful) {
          if (newHelpfulUsers.contains(currentUserId)) {
            // すでに「役に立った」に投票している場合は取り消し
            newHelpfulUsers.remove(currentUserId);
          } else {
            // 「役に立った」に投票
            newHelpfulUsers.add(currentUserId);
            // 「役に立たなかった」から削除
            newNotHelpfulUsers.remove(currentUserId);
          }
        } else {
          if (newNotHelpfulUsers.contains(currentUserId)) {
            // すでに「役に立たなかった」に投票している場合は取り消し
            newNotHelpfulUsers.remove(currentUserId);
          } else {
            // 「役に立たなかった」に投票
            newNotHelpfulUsers.add(currentUserId);
            // 「役に立った」から削除
            newHelpfulUsers.remove(currentUserId);
          }
        }

        transaction.update(postRef, {
          'helpfulUsers': newHelpfulUsers,
          'notHelpfulUsers': newNotHelpfulUsers,
          'helpfulCount': newHelpfulUsers.length,
          'notHelpfulCount': newNotHelpfulUsers.length,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('投票に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return AppTheme.primaryColor;
      case PostCategory.toilet:
        return AppTheme.secondaryColor;
      case PostCategory.food:
        return AppTheme.successColor;
      case PostCategory.merchandise:
        return AppTheme.accentColor;
      case PostCategory.transportation:
        return AppTheme.warningColor;
      case PostCategory.lost:
        return AppTheme.errorColor;
      case PostCategory.question:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return Icons.info;
      case PostCategory.toilet:
        return Icons.wc;
      case PostCategory.food:
        return Icons.restaurant;
      case PostCategory.merchandise:
        return Icons.shopping_bag;
      case PostCategory.transportation:
        return Icons.train;
      case PostCategory.lost:
        return Icons.help_outline;
      case PostCategory.question:
        return Icons.question_mark;
    }
  }

  String _getCategoryName(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return '一般';
      case PostCategory.toilet:
        return 'トイレ';
      case PostCategory.food:
        return '食べ物';
      case PostCategory.merchandise:
        return 'グッズ';
      case PostCategory.transportation:
        return '交通';
      case PostCategory.lost:
        return '落とし物';
      case PostCategory.question:
        return '質問';
    }
  }
}