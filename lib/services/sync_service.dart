import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'database_helper.dart';

/// Offline-first sync service.
///
/// Full sync strategy (order matters):
///   1. Check for a live network connection via [connectivity_plus].
///   2. Read all local BudgetCategories from SharedPreferences and POST each
///      to [POST /api/budgets]. Laravel uses firstOrCreate — fully idempotent.
///   3. Query SQLite for every transaction with sync_status = 0.
///   4. POST each pending transaction to [POST /api/transactions].
///   5. On HTTP 200 / 201, mark the local row as synced (sync_status = 1).
///   6. Any error for an individual row is silently caught — it stays pending
///      and will be retried on the next [attemptSync] call.
class SyncService {
  // ── Network gate ───────────────────────────────────────────────────────────

  /// Returns true when the device has at least one non-none connectivity result.
  static Future<bool> _isConnected() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fire-and-forget entry point.
  ///
  /// Safe to call without `await` — all errors are caught internally.
  static Future<void> attemptSync() async {
    // 1. Gate: abort immediately if offline.
    if (!await _isConnected()) return;

    // 2. Build authenticated headers once (single SharedPreferences read).
    final Map<String, String> headers = await ApiService.authHeaders();

    // 3. Sync budgets FIRST so the server has the correct categories and
    //    starting amounts before any transactions are associated with them.
    await _syncBudgets(headers);

    // 4. Read unsynced transactions from SQLite.
    final List<Map<String, dynamic>> pending =
        await DatabaseHelper.instance.getUnsyncedTransactions();

    // 5. Attempt to upload each pending transaction row.
    for (final row in pending) {
      await _uploadRow(row, headers);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Reads all local [BudgetCategory] objects from SharedPreferences and
  /// POSTs each one to [POST /api/budgets].
  ///
  /// Laravel uses `firstOrCreate` on its end, so this is fully idempotent —
  /// re-pushing an existing budget name will never create a duplicate.
  static Future<void> _syncBudgets(Map<String, String> headers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('budgetCategories_v2');
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(raw);
      print('[SyncService] Syncing ${decoded.length} local budget(s) to server...');

      for (final item in decoded) {
        final String name = item['name'] as String? ?? '';
        // startingBudget is stored as a number; safe-parse guards against
        // int/double/String type variance in the SharedPreferences JSON.
        final double startingAmount =
            double.tryParse(item['startingBudget'].toString()) ?? 0.0;

        if (name.isEmpty) continue;

        try {
          final response = await http
              .post(
                Uri.parse('${ApiService.baseUrl}/budgets'),
                headers: headers,
                body: jsonEncode({
                  'name': name,
                  'starting_amount': startingAmount,
                }),
              )
              .timeout(const Duration(seconds: 10));

          print('[SyncService] Budget "$name" → status ${response.statusCode}');
        } catch (e) {
          print('[SyncService] ✗ Failed to sync budget "$name": $e');
        }
      }
    } catch (e) {
      print('[SyncService] ✗ _syncBudgets error: $e');
    }
  }

  static Future<void> _uploadRow(
    Map<String, dynamic> row,
    Map<String, String> headers,
  ) async {
    try {
      print('[SyncService] Syncing item: "${row['item_name']}"');

      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/transactions'),
            headers: headers,
            body: jsonEncode({
              'budget_id': row['budget_id'],   // category name resolved server-side
              'type': row['type'],             // 'income' | 'expense'
              'amount': row['amount'],
              'item_name': row['item_name'],
              'quantity': row['quantity'],
              'notes': row['notes'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('[SyncService] Response status: ${response.statusCode}');
      print('[SyncService] Response body:   ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark this row as synced so it is never retried.
        await DatabaseHelper.instance.markAsSynced(row['id'] as int);
        print('[SyncService] ✓ Marked local id=${row['id']} as synced.');
      } else {
        // Server rejected the request (e.g. 422 validation, 401 auth error).
        // The row stays pending (sync_status = 0) and will be retried.
        print('[SyncService] ✗ Server rejected item "${row['item_name']}" '
            '(status ${response.statusCode}). Body: ${response.body}');
      }
    } catch (e) {
      // Timeout, socket error, etc. — row stays pending, retry next sync.
      print('[SyncService] ✗ Network error for "${row['item_name']}": $e');
    }
  }
}
