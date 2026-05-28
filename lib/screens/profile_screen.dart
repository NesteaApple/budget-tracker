import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getCachedUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out?',
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold)),
        content: Text(
          'You will be signed out of your account. Your local budget data will remain safe.',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    await ApiService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textMain = Theme.of(context).primaryColor;
    final Color textMuted = Theme.of(context).hintColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textMain,
        title: Text('Profile',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: textMain)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // ── AVATAR HERO ─────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            gradient: AppTheme.uiGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3F51B5)
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user?['name'] ?? 'User',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?['email'] ?? '—',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── INFO CARD ────────────────────────────────────────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.person_outline,
                                label: 'Full Name',
                                value: _user?['name'] ?? '—',
                                textMain: textMain,
                                textMuted: textMuted,
                              ),
                              Divider(
                                  height: 1,
                                  indent: 60,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade100),
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _user?['email'] ?? '—',
                                textMain: textMain,
                                textMuted: textMuted,
                              ),
                              if (_user?['id'] != null) ...[
                                Divider(
                                    height: 1,
                                    indent: 60,
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade100),
                                _InfoRow(
                                  icon: Icons.tag,
                                  label: 'Account ID',
                                  value: '#${_user!['id']}',
                                  textMain: textMain,
                                  textMuted: textMuted,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── LOGOUT BUTTON ────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoggingOut ? null : _handleLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: isDark ? 0.15 : 1.0),
                              foregroundColor: isDark
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.white,
                              elevation: isDark ? 0 : 4,
                              shadowColor: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: isDark
                                      ? BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error
                                              .withValues(alpha: 0.4))
                                      : BorderSide.none),
                            ),
                            icon: _isLoggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.logout),
                            label: Text(
                              _isLoggingOut ? 'Signing out…' : 'Sign Out',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _getInitials() {
    final name = (_user?['name'] as String?) ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}

// ── Info Row widget ────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textMain;
  final Color textMuted;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textMain,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: textMuted, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      color: textMain,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
