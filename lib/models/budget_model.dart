import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

enum AccountType { cash, bank, creditCard, investment }

enum DebtType { debt, credit }

class Account {
  final String? id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final String? color;
  final String? icon;

  Account({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'TRY',
    this.color,
    this.icon,
  });

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    String? color,
    String? icon,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
    };
  }

  factory Account.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AccountType.cash,
      ),
      balance: (data['balance'] as num).toDouble(),
      currency: data['currency'] ?? 'TRY',
      color: data['color'],
      icon: data['icon'],
    );
  }
}

class BudgetTransaction {
  final String? id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? subCategory;
  final DateTime date;
  final String description;
  final String? taskId;
  final String recurrence;
  final String? paymentMethod;
  final String? accountId;
  final String? toAccountId;
  final List<String> tags;

  BudgetTransaction({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.subCategory,
    required this.date,
    this.description = '',
    this.taskId,
    this.recurrence = 'none',
    this.paymentMethod,
    this.accountId,
    this.toAccountId,
    this.tags = const [],
  });

  BudgetTransaction copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? subCategory,
    DateTime? date,
    String? description,
    String? taskId,
    String? recurrence,
    String? paymentMethod,
    String? accountId,
    String? toAccountId,
    List<String>? tags,
  }) {
    return BudgetTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      description: description ?? this.description,
      taskId: taskId ?? this.taskId,
      recurrence: recurrence ?? this.recurrence,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'subCategory': subCategory,
      'date': Timestamp.fromDate(date),
      'description': description,
      'taskId': taskId,
      'recurrence': recurrence,
      'paymentMethod': paymentMethod,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'tags': tags,
    };
  }

  factory BudgetTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      category: data['category'] ?? 'Genel',
      subCategory: data['subCategory'],
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      taskId: data['taskId'],
      recurrence: data['recurrence'] ?? 'none',
      paymentMethod: data['paymentMethod'],
      accountId: data['accountId'],
      toAccountId: data['toAccountId'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}

class BudgetLimit {
  final String? id;
  final String userId;
  final String category;
  final String? subCategory;
  final double limitAmount;
  final String period;

  BudgetLimit({
    this.id,
    required this.userId,
    required this.category,
    this.subCategory,
    required this.limitAmount,
    this.period = 'monthly',
  });

  BudgetLimit copyWith({
    String? id,
    String? userId,
    String? category,
    String? subCategory,
    double? limitAmount,
    String? period,
  }) {
    return BudgetLimit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'subCategory': subCategory,
      'limitAmount': limitAmount,
      'period': period,
    };
  }

  factory BudgetLimit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetLimit(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? 'Genel',
      subCategory: data['subCategory'],
      limitAmount: (data['limitAmount'] as num).toDouble(),
      period: data['period'] ?? 'monthly',
    );
  }
}

class Debt {
  final String? id;
  final String userId;
  final String personName;
  final double amount;
  final DebtType type;
  final DateTime date;
  final DateTime? dueDate;
  final bool isPaid;
  final String? description;

  Debt({
    this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.isPaid = false,
    this.description,
  });

  Debt copyWith({
    String? id,
    String? userId,
    String? personName,
    double? amount,
    DebtType? type,
    DateTime? date,
    DateTime? dueDate,
    bool? isPaid,
    String? description,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isPaid': isPaid,
      'description': description,
    };
  }

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      userId: data['userId'] ?? '',
      personName: data['personName'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] == 'debt' ? DebtType.debt : DebtType.credit,
      date: (data['date'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isPaid: data['isPaid'] ?? false,
      description: data['description'],
    );
  }
}

class SavingsGoal {
  final String? id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? icon;

  SavingsGoal({
    this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.icon,
  });

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'icon': icon,
    };
  }

  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num).toDouble(),
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      icon: data['icon'],
    );
  }
}

enum AssetType {
  cash,
  bank,
  gold,
  currency,
  crypto,
  stockMarket,
  realEstate,
  vehicle,
  other
}

class Asset {
  final String? id;
  final String userId;
  final String name;
  final String symbol;
  final AssetType type;
  final double amount;
  final double currentValue;
  final double purchasePrice;
  final DateTime lastUpdated;

  Asset({
    this.id,
    required this.userId,
    required this.name,
    required this.symbol,
    required this.type,
    this.amount = 0.0,
    this.currentValue = 0.0,
    this.purchasePrice = 0.0,
    required this.lastUpdated,
  });

  Asset copyWith({
    String? id,
    String? userId,
    String? name,
    String? symbol,
    AssetType? type,
    double? amount,
    double? currentValue,
    double? purchasePrice,
    DateTime? lastUpdated,
  }) {
    return Asset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'symbol': symbol,
      'type': type.name,
      'amount': amount,
      'currentValue': currentValue,
      'purchasePrice': purchasePrice,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Asset(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      symbol: data['symbol'] ?? '',
      type: AssetType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AssetType.other,
      ),
      amount: (data['amount'] as num).toDouble(),
      currentValue: (data['currentValue'] as num).toDouble(),
      purchasePrice: (data['purchasePrice'] as num).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
