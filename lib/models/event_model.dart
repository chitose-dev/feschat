import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final String creatorUid;
  final String creatorNickname;
  final DateTime eventDate;
  final String venue;
  final bool isPublic;
  final String? password;
  final List<String> tags;
  final int participantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorUid,
    required this.creatorNickname,
    required this.eventDate,
    required this.venue,
    this.isPublic = true,
    this.password,
    this.tags = const [],
    this.participantCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      creatorNickname: data['creatorNickname'] ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      venue: data['venue'] ?? '',
      isPublic: data['isPublic'] ?? true,
      password: data['password'],
      tags: List<String>.from(data['tags'] ?? []),
      participantCount: data['participantCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorUid': creatorUid,
      'creatorNickname': creatorNickname,
      'eventDate': Timestamp.fromDate(eventDate),
      'venue': venue,
      'isPublic': isPublic,
      'password': password,
      'tags': tags,
      'participantCount': participantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}