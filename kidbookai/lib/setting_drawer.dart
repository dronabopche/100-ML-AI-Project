import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsDrawer extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;
  final User? user;

  const SettingsDrawer({
    Key? key,
    required this.onToggleTheme,
    required this.onSignOut,
    required this.user,
  }) : super(key: key);

  @override
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  bool _notifications = true;
  bool _autoSave = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Drawer(
      width: 300,
      child: Container(
        color: bgColor,
        child: Column(
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.orange.shade800, Colors.orange.shade600]
                      : [Colors.orange.shade500, Colors.orange.shade300],
                ),
              ),
              child: Column(
                children: [
                  if (widget.user != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: widget.user!.photoURL != null
                          ? NetworkImage(widget.user!.photoURL!)
                          : null,
                      backgroundColor: Colors.white,
                      child: widget.user!.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.orange.shade700,
                            )
                          : null,
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        size: 40,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user?.displayName ?? 'Guest User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user?.email ?? 'Not signed in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  /// ACCOUNT SECTION
                  _SectionTitle(title: 'Account'),
                  _DrawerTile(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {},
                  ),
                  _DrawerTile(
                    icon: Icons.history,
                    title: 'Activity History',
                    onTap: () {},
                  ),
                  _DrawerTile(
                    icon: Icons.favorite,
                    title: 'Saved Books',
                    onTap: () {},
                  ),

                  /// SETTINGS SECTION
                  _SectionTitle(title: 'Settings'),
                  _DrawerTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    trailing: Switch(
                      value: _notifications,
                      onChanged: (value) {
                        setState(() => _notifications = value);
                      },
                      activeColor: Colors.orange,
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.save,
                    title: 'Auto Save',
                    trailing: Switch(
                      value: _autoSave,
                      onChanged: (value) {
                        setState(() => _autoSave = value);
                      },
                      activeColor: Colors.orange,
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.color_lens,
                    title: 'Theme',
                    trailing: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.orange,
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                  ),

                  /// SUPPORT SECTION
                  _SectionTitle(title: 'Support'),
                  _DrawerTile(
                    icon: Icons.help,
                    title: 'Help & FAQ',
                    onTap: () {},
                  ),
                  _DrawerTile(
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    onTap: () {},
                  ),
                  _DrawerTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),

                  /// SIGN OUT
                  if (widget.user != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: widget.onSignOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.orange.shade600),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
