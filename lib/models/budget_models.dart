class TransactionItem {
  String name; 
  double amount; 
  int quantity; 
  String? notes; 
  bool isIncome;

  TransactionItem({required this.name, required this.amount, this.quantity = 1, this.notes, this.isIncome = false});
  
  double get totalValue => amount * quantity;

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'quantity': quantity, 'notes': notes, 'isIncome': isIncome};
  
  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    name: json['name'], 
    amount: json['amount'], 
    quantity: json['quantity'] ?? 1, 
    notes: json['notes'], 
    isIncome: json['isIncome'] ?? false
  );
}

class BudgetCategory {
  String name;
  double startingBudget;
  List<TransactionItem> history;

  /// Cached balance value returned by the Laravel API (`current_balance`).
  /// Named [serverBalance] to avoid a name collision with the local computed
  /// getter [currentBalance] below. Null when not hydrated from the server.
  final double? serverBalance;

  BudgetCategory({
    required this.name,
    required this.startingBudget,
    required this.history,
    this.serverBalance,   // optional — existing local call sites unchanged
  });

  // Calculates the current money left
  double get currentBalance {
    double balance = startingBudget;
    for (var item in history) {
      if (item.isIncome) {
        balance += item.totalValue; 
      } else {
        balance -= item.totalValue;
      }
    }
    return balance;
  }

  // NEW: Calculates the absolute maximum spending power for the circle visualizer!
  double get maxCapacity {
    double capacity = startingBudget;
    for (var item in history) {
      if (item.isIncome) {
        capacity += item.totalValue;
      }
    }
    return capacity;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'startingBudget': startingBudget,
    'history': history.map((e) => e.toJson()).toList(),
    if (serverBalance != null) 'current_balance': serverBalance,
  };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
    name: json['name'],
    startingBudget: json['startingBudget'],
    history: (json['history'] as List).map((e) => TransactionItem.fromJson(e)).toList(),
    // Safe parse: API may return int, double, or string for numeric fields.
    serverBalance: json['current_balance'] != null
        ? double.parse(json['current_balance'].toString())
        : null,
  );
}