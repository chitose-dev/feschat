import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  general, // 一般情報
  toilet, // トイレ情報
  food, // 食べ物・ドリンク
  merchandise, // グッズ
  transportation, // 交通情報
  lost, // 落とし物
  question, // 質問
}

class InfoPostModel {
  final String id;
  final String eventId;
  final String authorUid;
  final String authorNickname;
  final String? authorProfileImageUrl;
  final String title;
  final String content;
  final PostCategory category;
  final List<String> imageUrls;
  final int helpfulCount;
  final int notHelpfulCount;
  final List<String> helpfulUsers; // 役に立ったを押したユーザー
  final List<String> notHelpfulUsers; // 役に立たなかったを押したユーザー
  final bool isPinned; // 運営がピン止めできる機能
  final DateTime timestamp;
  final DateTime updatedAt;
  final bool isDeleted;

  InfoPostModel({
    required this.id,
    required this.eventId,
    required this.authorUid,
    required this.authorNickname,
    this.authorProfileImageUrl,
    required this.title,
    required this.content,
    this.category = PostCategory.general,
    this.imageUrls = const [],
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    this.helpfulUsers = const [],
    this.notHelpfulUsers = const [],
    this.isPinned = false,
    required this.timestamp,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory InfoPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InfoPostModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? '',
      authorProfileImageUrl: data['authorProfileImageUrl'],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: PostCategory.values.firstWhere(
            (e) => e.toString().split('.').last == data['category'],
        orElse: () => PostCategory.general,
      ),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      helpfulCount: data['helpfulCount'] ?? 0,
      notHelpfulCount: data['notHelpfulCount'] ?? 0,
      helpfulUsers: List<String>.from(data['helpfulUsers'] ?? []),
      notHelpfulUsers: List<String>.from(data['notHelpfulUsers'] ?? []),
      isPinned: data['isPinned'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'authorUid': authorUid,
      'authorNickname': authorNickname,
      'authorProfileImageUrl': authorProfileImageUrl,
      'title': title,
      'content': content,
      'category': category.toString().split('.').last,
      'imageUrls': imageUrls,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'helpfulUsers': helpfulUsers,
      'notHelpfulUsers': notHelpfulUsers,
      'isPinned': isPinned,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  // 役に立った/役に立たなかったの割合を計算
  double get helpfulRatio {
    final total = helpfulCount + notHelpfulCount;
    if (total == 0) return 0.0;
    return helpfulCount / total;
  }

  // ソート用のスコア計算
  double get sortScore {
    final total = helpfulCount + notHelpfulCount;
    if (total < 5) {
      // 投票数が少ない場合は時間重視
      final hoursSincePost = DateTime.now().difference(timestamp).inHours;
      return (100 - hoursSincePost).toDouble().clamp(0, 100); // 新しいほど高スコア、0-100の範囲に制限
    }
    // 投票数が多い場合は有用性重視
    return helpfulRatio * 100 + (helpfulCount * 0.1);
  }

  InfoPostModel copyWith({
    String? title,
    String? content,
    PostCategory? category,
    List<String>? imageUrls,
    int? helpfulCount,
    int? notHelpfulCount,
    List<String>? helpfulUsers,
    List<String>? notHelpfulUsers,
    bool? isPinned,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return InfoPostModel(
      id: id,
      eventId: eventId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorProfileImageUrl: authorProfileImageUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      helpfulUsers: helpfulUsers ?? this.helpfulUsers,
      notHelpfulUsers: notHelpfulUsers ?? this.notHelpfulUsers,
      isPinned: isPinned ?? this.isPinned,
      timestamp: timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}