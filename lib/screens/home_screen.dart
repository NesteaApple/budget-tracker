import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../main.dart'; 
import '../theme/app_theme.dart';
import '../models/budget_models.dart';

class BudgetHomeScreen extends StatefulWidget {
  const BudgetHomeScreen({super.key});
  @override
  State<BudgetHomeScreen> createState() => _BudgetHomeScreenState();
}

class _BudgetHomeScreenState extends State<BudgetHomeScreen> {
  List<BudgetCategory> categories = [];
  int activeIndex = 0; 
  bool isLoading = true;
  bool isSelectionMode = false;
  Set<int> selectedIndices = {};

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController(); 

  bool get hasWallets => categories.isNotEmpty;
  BudgetCategory? get activeCategory {
    if (hasWallets) {
      return categories[activeIndex];
    } else {
      return null;
    }
  }

  // --- DYNAMIC THEME COLORS ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textMain => Theme.of(context).primaryColor;
  Color get textMuted => Theme.of(context).hintColor;
  Color get cardColor => Theme.of(context).cardColor;
  Color get bgWhite => Theme.of(context).scaffoldBackgroundColor;
  Color get primaryGreen => Theme.of(context).colorScheme.secondary;
  Color get primaryRed => Theme.of(context).colorScheme.error;
  Color get primaryOrange => Theme.of(context).colorScheme.tertiary;
  Color get primaryBlue => const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? dataString = prefs.getString('budgetCategories_v2');
      if (dataString == null) {
        categories.add(BudgetCategory(name: 'General Budget', startingBudget: 1000.00, history: []));
      } else {
        List<dynamic> decodedList = jsonDecode(dataString);
        categories = decodedList.map((item) => BudgetCategory.fromJson(item)).toList();
      }
      if (activeIndex >= categories.length) {
        activeIndex = 0;
      }
      
      bool savedDark = prefs.getBool('isDarkMode') ?? false;
      themeNotifier.value = savedDark ? ThemeMode.dark : ThemeMode.light;
      
      isLoading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String dataString = jsonEncode(categories.map((c) => c.toJson()).toList());
    prefs.setString('budgetCategories_v2', dataString);
  }

  Color getHealthColor() {
    if (!hasWallets || activeCategory!.maxCapacity == 0) {
      return textMuted;
    }
    double percentage = activeCategory!.currentBalance / activeCategory!.maxCapacity;
    if (percentage > 0.5) {
      return primaryGreen;
    }
    if (percentage > 0.2) {
      return primaryOrange;
    }
    return primaryRed;
  }

  bool get isAllSelected => activeCategory != null && selectedIndices.length == activeCategory!.history.length && activeCategory!.history.isNotEmpty;

  void toggleSelectAll() {
    setState(() {
      if (isAllSelected) {
        selectedIndices.clear();
      } else {
        selectedIndices = List.generate(activeCategory!.history.length, (index) => index).toSet();
      }
    });
  }

  void _showAddOrEditCategoryDialog({bool isEditing = false}) {
    if (isEditing) {
      _categoryNameController.text = activeCategory!.name; 
      _budgetController.text = activeCategory!.startingBudget.toStringAsFixed(0);
    } else {
      _categoryNameController.clear(); 
      _budgetController.clear();
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? nameError; String? budgetError;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit Budget' : 'New Budget', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain)),
                      const SizedBox(height: 24),
                      TextField(controller: _categoryNameController, onChanged: (val) { if (nameError != null) setModalState(() => nameError = null); }, decoration: InputDecoration(labelText: 'Budget Name', errorText: nameError, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 16),
                      TextField(controller: _budgetController, keyboardType: TextInputType.number, onChanged: (val) { if (budgetError != null) setModalState(() => budgetError = null); }, decoration: InputDecoration(labelText: 'Starting Budget (₱)', errorText: budgetError, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryBlue : textMain, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () {
                            String name = _categoryNameController.text.trim(); String budgetText = _budgetController.text.trim(); double? budget = double.tryParse(budgetText); bool hasError = false;
                            if (name.isEmpty) { nameError = 'Required'; hasError = true; } else { nameError = null; }
                            if (budgetText.isEmpty) { budgetError = 'Required'; hasError = true; } else if (budget == null) { budgetError = 'Invalid number'; hasError = true; } else { budgetError = null; }
                            if (hasError) { setModalState(() {}); return; }

                            setState(() {
                              if (isEditing) { 
                                activeCategory!.name = name; activeCategory!.startingBudget = budget!; 
                              } else { 
                                categories.add(BudgetCategory(name: name, startingBudget: budget!, history: [])); activeIndex = categories.length - 1; 
                              }
                            });
                            saveData(); Navigator.pop(context); 
                          },
                          child: Text(isEditing ? 'Update Budget' : 'Create Budget', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _confirmDeleteWallet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Budget?', style: TextStyle(color: textMain)),
        content: Text('Delete "${activeCategory!.name}" and all its history?', style: TextStyle(color: textMain)),
        actions: [
          TextButton(child: Text('Cancel', style: TextStyle(color: textMuted)), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              setState(() {
                categories.removeAt(activeIndex);
                if (activeIndex >= categories.length) {
                  activeIndex = (categories.length - 1).clamp(0, 999);
                }
                isSelectionMode = false; selectedIndices.clear();
              });
              saveData(); Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmSingleDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction?', style: TextStyle(color: textMain)),
        content: Text('Are you sure you want to delete this item?', style: TextStyle(color: textMain)),
        actions: [
          TextButton(child: Text('Cancel', style: TextStyle(color: textMuted)), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { setState(() { activeCategory!.history.removeAt(index); }); saveData(); Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddChoiceDialog() {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('What would you like to add?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain)), const SizedBox(height: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                  leading: CircleAvatar(backgroundColor: primaryGreen.withValues(alpha: 0.15), child: Icon(Icons.add, color: primaryGreen)),
                  title: Text('Add Income / Top-up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain)),
                  onTap: () { Navigator.pop(context); _showTransactionForm(isIncomeMode: true); },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                  leading: CircleAvatar(backgroundColor: primaryRed.withValues(alpha: 0.15), child: Icon(Icons.remove, color: primaryRed)),
                  title: Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain)),
                  onTap: () { Navigator.pop(context); _showTransactionForm(isIncomeMode: false); },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showTransactionForm({int? editIndex, required bool isIncomeMode}) {
    if (!hasWallets) return; 
    bool isEditing = editIndex != null;
    if (isEditing) {
      final item = activeCategory!.history[editIndex];
      _itemController.text = item.name; _amountController.text = item.amount.toStringAsFixed(2); _qtyController.text = item.quantity.toString(); _notesController.text = item.notes ?? ''; isIncomeMode = item.isIncome;
    } else {
      _itemController.clear(); _amountController.clear(); _qtyController.text = '1'; _notesController.clear();
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? nameError; String? amountError;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit Transaction' : isIncomeMode ? 'New Income' : 'New Expense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain)),
                      const SizedBox(height: 24),
                      TextField(controller: _itemController, onChanged: (val) { if (nameError != null) setModalState(() => nameError = null); }, decoration: InputDecoration(labelText: isIncomeMode ? 'Income Source' : 'What did you buy?', errorText: nameError, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: TextField(controller: _amountController, keyboardType: TextInputType.number, onChanged: (val) { if (amountError != null) setModalState(() => amountError = null); }, decoration: InputDecoration(labelText: 'Amount (₱)', errorText: amountError, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                          if (!isIncomeMode) ...[const SizedBox(width: 16), Expanded(flex: 1, child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Qty', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))]
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: _notesController, decoration: InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isIncomeMode ? primaryGreen : (isDark ? primaryBlue : textMain), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () {
                            String name = _itemController.text.trim(); String amountText = _amountController.text.trim(); double? amount = double.tryParse(amountText); bool hasError = false;
                            if (name.isEmpty) { nameError = 'Required'; hasError = true; } else { nameError = null; }
                            if (amountText.isEmpty) { amountError = 'Required'; hasError = true; } else if (amount == null) { amountError = 'Invalid number'; hasError = true; } else { amountError = null; }
                            if (hasError) { setModalState(() {}); return; }

                            int qty = int.tryParse(_qtyController.text) ?? 1;
                            if (isIncomeMode) {
                              qty = 1; 
                            }

                            setState(() {
                              TransactionItem newItem = TransactionItem(name: name, amount: amount!, quantity: qty, notes: _notesController.text.isEmpty ? null : _notesController.text, isIncome: isIncomeMode);
                              if (isEditing) {
                                activeCategory!.history[editIndex] = newItem; 
                              } else {
                                activeCategory!.history.insert(0, newItem);
                              }
                            });
                            saveData(); Navigator.pop(context); 
                          },
                          child: const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24), 
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showItemDetails(int index) {
    if (!hasWallets) return;
    final item = activeCategory!.history[index];
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: item.isIncome ? primaryGreen : primaryRed, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item.isIncome ? 'Amount:' : 'Price per item:', style: TextStyle(fontSize: 16, color: textMuted)), Text('₱${item.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textMain))]),
                if (!item.isIncome) ...[const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Quantity:', style: TextStyle(fontSize: 16, color: textMuted)), Text('${item.quantity}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textMain))])],
                const Divider(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain)), Text('₱${item.totalValue.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.isIncome ? primaryGreen : primaryRed))]),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted)), const SizedBox(height: 8),
                  Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgWhite, borderRadius: BorderRadius.circular(12)), child: Text(item.notes!, style: TextStyle(fontSize: 16, color: textMain)))
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: primaryBlue, side: BorderSide(color: primaryBlue), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      onPressed: () { Navigator.pop(context); _showTransactionForm(editIndex: index, isIncomeMode: item.isIncome); }, 
                      icon: const Icon(Icons.edit), label: const Text('Edit')
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryRed.withValues(alpha: 0.2) : Colors.red.shade50, foregroundColor: primaryRed, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), elevation: 0),
                      onPressed: () => _confirmSingleDelete(index), icon: const Icon(Icons.delete), label: const Text('Delete'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void toggleSelectionMode() { setState(() { isSelectionMode = !isSelectionMode; selectedIndices.clear(); }); }
  void toggleItemSelection(int index) { setState(() { if (selectedIndices.contains(index)) { selectedIndices.remove(index); } else { selectedIndices.add(index); } }); }
  
  void confirmBatchDelete() {
    if (selectedIndices.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Selected?', style: TextStyle(color: textMain)), 
        content: Text('Delete ${selectedIndices.length} items?', style: TextStyle(color: textMain)),
        actions: [
          TextButton(child: Text('Cancel', style: TextStyle(color: textMuted)), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              setState(() {
                List<int> sorted = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
                for (int i in sorted) {
                  activeCategory!.history.removeAt(i);
                }
                isSelectionMode = false; selectedIndices.clear();
              });
              saveData(); Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator(color: primaryBlue)));

    return Scaffold(
      backgroundColor: bgWhite, 
      appBar: AppBar(
        backgroundColor: bgWhite, elevation: 0, foregroundColor: textMain, 
        title: Text(hasWallets ? activeCategory!.name : 'Budget Tracker', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: hasWallets ? [
          if (isSelectionMode)
            IconButton(
              icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, color: textMain),
              tooltip: isAllSelected ? 'Deselect All' : 'Select All',
              onPressed: toggleSelectAll,
            ),
          IconButton(icon: Icon(isSelectionMode ? Icons.close : Icons.checklist_rtl, color: textMain), onPressed: toggleSelectionMode),
          if (!isSelectionMode)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textMain),
              onSelected: (val) { if (val == 'edit') _showAddOrEditCategoryDialog(isEditing: true); if (val == 'delete') _confirmDeleteWallet(); },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Edit Budget Details', style: TextStyle(color: primaryBlue))),
                const PopupMenuItem(value: 'delete', child: Text('Delete Entire Budget', style: TextStyle(color: Colors.red))),
              ],
            )
        ] : null,
      ),
      drawer: _buildDrawer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: hasWallets && !isSelectionMode ? FloatingActionButton(
        shape: const CircleBorder(), backgroundColor: isDark ? primaryBlue : textMain, foregroundColor: Colors.white, elevation: 8,
        onPressed: _showAddChoiceDialog, child: const Icon(Icons.add, size: 32),
      ) : null,
      bottomNavigationBar: hasWallets && !isSelectionMode ? BottomAppBar(shape: const CircularNotchedRectangle(), notchMargin: 8.0, color: cardColor, child: Container(height: 50.0)) : null,
            
      body: SafeArea(
        child: hasWallets 
          ? Column(
              children: [
                if (isSelectionMode) 
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16), color: primaryRed.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedIndices.length} Selected', style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
                        ElevatedButton.icon(onPressed: confirmBatchDelete, icon: const Icon(Icons.delete), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white)),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Remaining Budget', style: TextStyle(color: textMuted, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                            Text('₱ ${activeCategory!.currentBalance.toStringAsFixed(0)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textMain)), const SizedBox(height: 8),
                            Text('of ₱${activeCategory!.maxCapacity.toStringAsFixed(0)}', style: TextStyle(color: textMuted)),
                          ],
                        ),
                        SizedBox(
                          height: 80, width: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(value: activeCategory!.maxCapacity == 0 ? 0 : (activeCategory!.currentBalance / activeCategory!.maxCapacity).clamp(0.0, 1.0), strokeWidth: 8, backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(getHealthColor())),
                              Center(child: Icon(activeCategory!.currentBalance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber_rounded, color: getHealthColor(), size: 32))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5), child: Align(alignment: Alignment.centerLeft, child: Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)))),

                Expanded(
                  child: activeCategory!.history.isEmpty
                      ? Center(child: Text('No transactions yet.', style: TextStyle(color: textMuted, fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                          itemCount: activeCategory!.history.length,
                          itemBuilder: (context, index) {
                            final item = activeCategory!.history[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: AppTheme.asymmetricCard(item.isIncome ? AppTheme.incomeGradient : AppTheme.expenseGradient),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: isSelectionMode ? () => toggleItemSelection(index) : () => _showItemDetails(index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        if (isSelectionMode) Padding(padding: const EdgeInsets.only(right: 15), child: Icon(selectedIndices.contains(index) ? Icons.check_circle : Icons.circle_outlined, color: Colors.white))
                                        else Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(item.isIncome ? Icons.add : Icons.shopping_bag, color: Colors.white)),
                                        if (!isSelectionMode) const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4),
                                              Text(item.notes ?? (item.isIncome ? 'Added to budget' : '${item.quantity} item(s)'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Text('${item.isIncome ? '+' : '-'}₱${item.totalValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 100, color: textMuted.withValues(alpha: 0.3)), const SizedBox(height: 20),
                  Text('Your budget list is empty.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textMain)), const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditCategoryDialog(), icon: const Icon(Icons.add), label: const Text('Create a Budget', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryBlue : textMain, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  )
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDrawer() {
      return Drawer(
        backgroundColor: cardColor,
        child: Column(
          children: [
            // 1. THE HEADER (Pushed down safely below the physical status bar)
            Container(
              width: double.infinity, 
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20, 
                bottom: 20
              ), 
              decoration: const BoxDecoration(gradient: AppTheme.uiGradient),
              child: const Column(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 50), 
                  SizedBox(height: 10), 
                  Text('My Budgets', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                ]
              ),
            ),
            
            // 2. THE SCROLLABLE LIST
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero, // Removes weird default gaps
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.folder, color: activeIndex == index ? primaryBlue : textMuted),
                    title: Text(categories[index].name, style: TextStyle(fontWeight: activeIndex == index ? FontWeight.bold : FontWeight.normal, color: textMain)),
                    selected: activeIndex == index, selectedColor: primaryBlue,
                    onTap: () { setState(() { activeIndex = index; isSelectionMode = false; selectedIndices.clear(); }); Navigator.pop(context); },
                  );
                },
              ),
            ),
            
            // 3. THE PINNED BOTTOM ACTIONS (Protected by a strict SafeArea and extra padding)
            Container(
              color: cardColor,
              child: SafeArea(
                top: false, // We only care about protecting the bottom from the nav bar here
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.add, color: isDark ? primaryBlue : textMain), 
                      title: Text('Add New Budget', style: TextStyle(fontWeight: FontWeight.bold, color: textMain)), 
                      onTap: () { Navigator.pop(context); _showAddOrEditCategoryDialog(); }
                    ),
                    SwitchListTile(
                      title: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, color: textMain)),
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? primaryBlue : textMuted),
                      value: isDark,
                      activeTrackColor: primaryBlue.withValues(alpha: 0.4), // Fixed warning!
                      activeThumbColor: primaryBlue,
                      onChanged: (bool value) async {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('isDarkMode', value); 
                      },
                    ),
                    // THE FIX: Extra breathing room specifically for web/emulators!
                    const SizedBox(height: 24), 
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }