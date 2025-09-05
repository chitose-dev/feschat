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
  final String? imageUrl;
  final bool requiresLocation;
  final double? latitude;
  final double? longitude;
  final double? locationRadius;
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
    this.imageUrl,
    this.requiresLocation = false,
    this.latitude,
    this.longitude,
    this.locationRadius,
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
      imageUrl: data['imageUrl'],
      requiresLocation: data['requiresLocation'] ?? false,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationRadius: data['locationRadius']?.toDouble(),
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
      'imageUrl': imageUrl,
      'requiresLocation': requiresLocation,
      'latitude': latitude,
      'longitude': longitude,
      'locationRadius': locationRadius,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EventModel copyWith({
    String? name,
    String? description,
    DateTime? eventDate,
    String? venue,
    bool? isPublic,
    String? password,
    List<String>? tags,
    int? participantCount,
    String? imageUrl,
    bool? requiresLocation,
    double? latitude,
    double? longitude,
    double? locationRadius,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorUid: creatorUid,
      creatorNickname: creatorNickname,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      isPublic: isPublic ?? this.isPublic,
      password: password ?? this.password,
      tags: tags ?? this.tags,
      participantCount: participantCount ?? this.participantCount,
      imageUrl: imageUrl ?? this.imageUrl,
      requiresLocation: requiresLocation ?? this.requiresLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationRadius: locationRadius ?? this.locationRadius,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
