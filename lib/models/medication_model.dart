import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String? id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final int color;
  final String icon;
  final String notes;
  final bool isActive;
  final bool reminderEnabled;

  final Map<String, List<String>> takenHistory;

  final int stock;
  final int stockThreshold;
  final bool stockTracking;

  final String? imageUrl;
  final String? prospectusUrl;
  final String? barcode;
  final String? genericName;
  final String? atcCode;
  final List<String> categories;

  Medication({
    this.id,
    required this.userId,
    required this.name,
    this.dosage = '',
    this.frequency = 'daily',
    this.times = const ['08:00'],
    required this.startDate,
    this.endDate,
    this.color = 0xFF4CAF50,
    this.icon = '💊',
    this.notes = '',
    this.isActive = true,
    this.reminderEnabled = true,
    this.takenHistory = const {},
    this.stock = 0,
    this.stockThreshold = 5,
    this.stockTracking = false,
    this.imageUrl,
    this.prospectusUrl,
    this.barcode,
    this.genericName,
    this.atcCode,
    this.categories = const [],
  });

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    int? color,
    String? icon,
    String? notes,
    bool? isActive,
    bool? reminderEnabled,
    Map<String, List<String>>? takenHistory,
    int? stock,
    int? stockThreshold,
    bool? stockTracking,
    String? imageUrl,
    String? prospectusUrl,
    String? barcode,
    String? genericName,
    String? atcCode,
    List<String>? categories,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      takenHistory: takenHistory ?? this.takenHistory,
      stock: stock ?? this.stock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      stockTracking: stockTracking ?? this.stockTracking,
      imageUrl: imageUrl ?? this.imageUrl,
      prospectusUrl: prospectusUrl ?? this.prospectusUrl,
      barcode: barcode ?? this.barcode,
      genericName: genericName ?? this.genericName,
      atcCode: atcCode ?? this.atcCode,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'color': color,
      'icon': icon,
      'notes': notes,
      'isActive': isActive,
      'reminderEnabled': reminderEnabled,
      'takenHistory': takenHistory,
      'stock': stock,
      'stockThreshold': stockThreshold,
      'stockTracking': stockTracking,
      'imageUrl': imageUrl,
      'prospectusUrl': prospectusUrl,
      'barcode': barcode,
      'genericName': genericName,
      'atcCode': atcCode,
      'categories': categories,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map, String docId) {
    final Map<String, List<String>> history = {};
    if (map['takenHistory'] != null) {
      final raw = map['takenHistory'] as Map<String, dynamic>;
      raw.forEach((k, v) {
        if (v is List) {
          history[k] = v.map((e) => e.toString()).toList();
        }
      });
    }

    return Medication(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'daily',
      times:
          (map['times'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              ['08:00'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      color: map['color'] ?? 0xFF4CAF50,
      icon: map['icon'] ?? '💊',
      notes: map['notes'] ?? '',
      isActive: map['isActive'] ?? true,
      reminderEnabled: map['reminderEnabled'] ?? true,
      takenHistory: history,
      stock: map['stock'] ?? 0,
      stockThreshold: map['stockThreshold'] ?? 5,
      stockTracking: map['stockTracking'] ?? false,
      imageUrl: map['imageUrl'],
      prospectusUrl: map['prospectusUrl'],
      barcode: map['barcode'],
      genericName: map['genericName'],
      atcCode: map['atcCode'],
      categories: (map['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
