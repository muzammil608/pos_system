import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    required this.photoUrl,
    required this.userName,
    this.radius = 20,
    this.fontSize = 16,
  });

  final String? photoUrl;
  final String userName;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    String? resolvedUrl;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      resolvedUrl = photoUrl!.contains('googleusercontent.com')
          ? '${photoUrl!.split('=').first}=s400'
          : photoUrl;
    }

    if (resolvedUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primary,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => _InitialAvatar(
              userName: userName,
              radius: radius,
              fontSize: fontSize,
            ),
            errorWidget: (context, url, error) => _InitialAvatar(
              userName: userName,
              radius: radius,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }

    return _InitialAvatar(
      userName: userName,
      radius: radius,
      fontSize: fontSize,
    );
  }
}

class AppDrawerAvatarButton extends StatelessWidget {
  const AppDrawerAvatarButton({
    super.key,
    required this.photoUrl,
    required this.userName,
  });

  final String? photoUrl;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (builderContext) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => Scaffold.of(builderContext).openDrawer(),
          child: AppUserAvatar(
            photoUrl: photoUrl,
            userName: userName,
            radius: 18,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.auth,
    required this.currentRoute,
  });

  final AuthProvider auth;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final userEmail = user?.email ?? 'No Email';
    final userName = user?.displayName ??
        (userEmail.contains('@') ? userEmail.split('@').first : userEmail);
    final photoUrl = user?.photoURL;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'POS System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Restaurant POS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (auth.isAdmin || auth.isCashier)
                  _DrawerItem(
                    icon: Icons.point_of_sale,
                    title: 'POS',
                    route: '/pos',
                    currentRoute: currentRoute,
                  ),
                if (auth.isAdmin)
                  _DrawerItem(
                    icon: Icons.analytics,
                    title: 'Admin Dashboard',
                    route: '/admin',
                    currentRoute: currentRoute,
                  ),
                if (auth.isAdmin)
                  _DrawerItem(
                    icon: Icons.receipt_long,
                    title: 'Orders Report',
                    route: '/orders',
                    currentRoute: currentRoute,
                  ),
                if (auth.isAdmin)
                  _DrawerItem(
                    icon: Icons.inventory_2,
                    title: 'Products',
                    route: '/products',
                    currentRoute: currentRoute,
                  ),
                if (auth.isAdmin)
                  _DrawerItem(
                    icon: Icons.people,
                    title: 'Employee Manager',
                    route: '/employees',
                    currentRoute: currentRoute,
                  ),
                if (auth.isAdmin || auth.isKitchen)
                  _DrawerItem(
                    icon: Icons.kitchen,
                    title: 'Kitchen',
                    route: '/kitchen',
                    currentRoute: currentRoute,
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppUserAvatar(
                  photoUrl: photoUrl,
                  userName: userName,
                  radius: 28,
                  fontSize: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  auth.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final selected = route == currentRoute;

    return ListTile(
      selected: selected,
      selectedColor: AppTheme.primary,
      selectedTileColor: AppTheme.primary.withOpacity(0.16),
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (!selected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.userName,
    required this.radius,
    required this.fontSize,
  });

  final String userName;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
