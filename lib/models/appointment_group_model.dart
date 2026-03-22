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
  });

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
    };
  }

  factory AppointmentGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentGroup(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      businessName: data['businessName'] ?? 'İşletme',
      businessPhone: data['businessPhone'],
      businessWebsite: data['businessWebsite'],
      businessAddress: data['businessAddress'],
      mapUrl: data['mapUrl'],
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'TL',
      durationMinutes: data['durationMinutes'] ?? 30,
      bufferMinutes: data['bufferMinutes'] ?? 0,
      minCancellationHours: data['minCancellationHours'] ?? 24,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      startHour: data['startHour'] ?? 9,
      endHour: data['endHour'] ?? 17,
      groupCode: data['groupCode'] ?? '',
      workingDays: List<int>.from(data['workingDays'] ?? [1, 2, 3, 4, 5]),
      breaks: List<Map<String, dynamic>>.from(data['breaks'] ?? [])
          .map((e) => Map<String, int>.from(e))
          .toList(),
    );
  }

  static String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "BOOK-$code";
  }
}
