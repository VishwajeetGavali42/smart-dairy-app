import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final addressController = TextEditingController(text: user?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: addressController,
                  label: 'Default Address',
                  prefixIcon: Icons.home_outlined,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await auth.updateProfile(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context, auth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'guest@example.com',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Verified Member',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats Row
            Row(
              children: [
                _buildStatItem(
                  'Orders',
                  '${orderProvider.orders.length}',
                  Icons.shopping_bag_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Wishlist',
                  '${productProvider.favoriteProductIds.length}',
                  Icons.favorite_border,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Coupons',
                  '4',
                  Icons.local_offer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Options Menu
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: user?.phone ?? 'Set phone number',
                      onTap: () => _showEditProfileDialog(context, auth),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildMenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery Address',
                      subtitle: user?.address ?? '742 Evergreen Terrace',
                      onTap: () => _showEditProfileDialog(context, auth),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildMenuTile(
                      icon: Icons.history,
                      title: 'Order History',
                      subtitle: orderProvider.orders.isEmpty
                          ? 'Track your purchases & status'
                          : '${orderProvider.orders.length} order(s) placed',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildMenuTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Order tracking & exclusive alerts',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications are up to date!')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildMenuTile(
                      icon: Icons.help_outline,
                      title: 'Customer Support',
                      subtitle: '24/7 shopping support team',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer support: support@smartdairy.coop')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              text: 'Sign Out',
              icon: Icons.logout,
              isOutlined: true,
              backgroundColor: const Color(0xFFEF4444),
              textColor: const Color(0xFFEF4444),
              onPressed: () => _confirmLogout(context, auth),
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart Dairy App v1.0.0 • Cooperative Dairy Management',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF2563EB)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
