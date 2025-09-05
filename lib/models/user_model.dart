import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String? bio;
  final String? prefecture;
  final String? gender;
  final String? ageGroup;
  final bool showPrefecture;
  final bool showGender;
  final bool showAgeGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    this.bio,
    this.prefecture,
    this.gender,
    this.ageGroup,
    this.showPrefecture = false,
    this.showGender = false,
    this.showAgeGroup = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      prefecture: data['prefecture'],
      gender: data['gender'],
      ageGroup: data['ageGroup'],
      showPrefecture: data['showPrefecture'] ?? false,
      showGender: data['showGender'] ?? false,
      showAgeGroup: data['showAgeGroup'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'prefecture': prefecture,
      'gender': gender,
      'ageGroup': ageGroup,
      'showPrefecture': showPrefecture,
      'showGender': showGender,
      'showAgeGroup': showAgeGroup,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? email,
    String? nickname,
    String? profileImageUrl,
    String? bio,
    String? prefecture,
    String? gender,
    String? ageGroup,
    bool? showPrefecture,
    bool? showGender,
    bool? showAgeGroup,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      prefecture: prefecture ?? this.prefecture,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      showPrefecture: showPrefecture ?? this.showPrefecture,
      showGender: showGender ?? this.showGender,
      showAgeGroup: showAgeGroup ?? this.showAgeGroup,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
