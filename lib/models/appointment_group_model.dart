import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AppointmentGroup {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String businessName;
  final String? businessPhone;
  final String? businessWebsite;
  final String? businessAddress;
  final String? mapUrl;
  final double price;
  final String currency;

  final int durationMinutes;
  final int bufferMinutes;
  final int minCancellationHours;

  final DateTime startDate;
  final DateTime endDate;
  final int startHour;
  final int endHour;
  final String groupCode;
  final List<int> workingDays;
  final List<Map<String, int>> breaks;

  final int color;
  final String icon;
  final String category;
  final bool isActive;

  AppointmentGroup({
    this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    required this.businessName,
    this.businessPhone,
    this.businessWebsite,
    this.businessAddress,
    this.mapUrl,
    this.price = 0.0,
    this.currency = 'TL',
    required this.durationMinutes,
    this.bufferMinutes = 0,
    this.minCancellationHours = 24,
    required this.startDate,
    required this.endDate,
    required this.startHour,
    required this.endHour,
    required this.groupCode,
    required this.workingDays,
    this.breaks = const [],
    this.color = 0xFF8B5CF6,
    this.icon = 'calendar_today',
    this.category = 'general',
    this.isActive = true,
  });

  static const List<int> serviceColors = [
    0xFF8B5CF6, // Mor
    0xFF3B82F6, // Mavi
    0xFF06B6D4, // Cyan
    0xFF10B981, // Yeşil
    0xFFF59E0B, // Amber
    0xFFEF4444, // Kırmızı
    0xFFF472B6, // Pembe
    0xFFE65100, // Turuncu
  ];

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'businessName': businessName,
      'businessPhone': businessPhone,
      'businessWebsite': businessWebsite,
      'businessAddress': businessAddress,
      'mapUrl': mapUrl,
      'price': price,
      'currency': currency,
      'durationMinutes': durationMinutes,
      'bufferMinutes': bufferMinutes,
      'minCancellationHours': minCancellationHours,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startHour': startHour,
      'endHour': endHour,
      'groupCode': groupCode,
      'workingDays': workingDays,
      'breaks': breaks,
      'color': color,
      'icon': icon,
      'category': category,
      'isActive': isActive,
    };
  }

  factory AppointmentGroup.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return AppointmentGroup(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      businessName: data['businessName'] ?? '',
      businessPhone: data['businessPhone'],
      businessWebsite: data['businessWebsite'],
      businessAddress: data['businessAddress'],
      mapUrl: data['mapUrl'],
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'TL',
      durationMinutes: data['durationMinutes'] ?? 30,
      bufferMinutes: data['bufferMinutes'] ?? 0,
      minCancellationHours: data['minCancellationHours'] ?? 24,
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      startHour: data['startHour'] ?? 9,
      endHour: data['endHour'] ?? 17,
      groupCode: data['groupCode'] ?? '',
      workingDays: List<int>.from(data['workingDays'] ?? [1, 2, 3, 4, 5]),
      breaks: List<Map<String, dynamic>>.from(data['breaks'] ?? [])
          .map((e) =>
              e.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),)
          .toList(),
      color: data['color'] ?? 0xFF8B5CF6,
      icon: data['icon'] ?? 'calendar_today',
      category: data['category'] ?? 'general',
      isActive: data['isActive'] ?? true,
    );
  }

  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),),);
    return 'BOOK-$code';
  }
}
