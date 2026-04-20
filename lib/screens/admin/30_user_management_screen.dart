import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';

import '../../widgets/admin/admin_sidebar.dart';

import '../../providers/admin_provider.dart';

import '../../models/user_model.dart';



class UserManagementScreen extends StatefulWidget {

  const UserManagementScreen({super.key});



  @override

  State<UserManagementScreen> createState() => _UserManagementScreenState();

}



class _UserManagementScreenState extends State<UserManagementScreen> {

  String _selectedRoleFilter = 'All';

  String _selectedStatusFilter = 'All';

  List<UserModel> _filteredUsers = [];

  Set<String> _selectedUsers = {};



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      context.read<AdminProvider>().fetchUsers();

    });

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.backgroundGray,

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: Row(

          children: [

            const Icon(Icons.eco, color: AppColors.primaryGreen),

            const SizedBox(width: 8),

            const Text(

              'User Management',

              style: TextStyle(

                color: AppColors.primaryGreen,

                fontWeight: FontWeight.bold,

                fontSize: 18,

              ),

            ),

          ],

        ),

        leading: Builder(

          builder: (context) => IconButton(

            icon: const Icon(Icons.menu, color: AppColors.textDark),

            onPressed: () => Scaffold.of(context).openDrawer(),

          ),

        ),

      ),

      drawer: const AdminSidebar(selectedRoute: '/admin/users'),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            _buildHeader(),

            const SizedBox(height: 24),

            _buildFilters(),

            const SizedBox(height: 24),

            _buildUserList(),

          ],

        ),

      ),

    );

  }



  Widget _buildHeader() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'USER MANAGEMENT',

          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),

        ),

        const Text(

          'Manage System Users',

          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),

        ),

        const SizedBox(height: 16),

        _buildActionButtons(),

      ],

    );

  }



  Widget _buildActionButtons() {

    return Column(

      children: [

        _buildActionButton(Icons.add, 'Add New User', Colors.white, AppColors.textDark),

        const SizedBox(height: 12),

        _buildActionButton(Icons.download, 'Export Users', AppColors.primaryGreen, Colors.white),

        const SizedBox(height: 12),

        _buildActionButton(Icons.upload, 'Import Users', AppColors.primaryOrange, Colors.white),

      ],

    );

  }



  Widget _buildActionButton(IconData icon, String label, Color bgColor, Color textColor, {VoidCallback? onPressed}) {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton.icon(

        onPressed: onPressed ?? () {},

        icon: Icon(icon, size: 16, color: textColor),

        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),

        style: ElevatedButton.styleFrom(

          backgroundColor: bgColor,

          elevation: 0,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: bgColor == Colors.white ? BorderSide(color: Colors.grey.shade300) : BorderSide.none),

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        ),

      ),

    );

  }



  Widget _buildFilters() {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.shade200),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            'Filters',

            style: TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.bold,

              color: AppColors.textDark,

            ),

          ),

          const SizedBox(height: 16),

          _buildRoleFilter(),

          const SizedBox(height: 12),

          _buildStatusFilter(),

        ],

      ),

    );

  }



  Widget _buildRoleFilter() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Role',

          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),

        ),

        const SizedBox(height: 8),

        SingleChildScrollView(

          scrollDirection: Axis.horizontal,

          child: Row(

            children: ['All', 'Admin', 'Business Owner', 'Manager', 'Driver'].map((role) {

              return Padding(

                padding: const EdgeInsets.only(right: 8),

                child: FilterChip(

                  label: Text(role),

                  selected: _selectedRoleFilter == role,

                  onSelected: (selected) {

                    setState(() {

                      _selectedRoleFilter = role;

                      _applyFilters();

                    });

                  },

                  selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),

                  labelStyle: TextStyle(

                    color: _selectedRoleFilter == role ? AppColors.primaryGreen : AppColors.textDark,

                  ),

                ),

              );

            }).toList(),

          ),

        ),

      ],

    );

  }



  Widget _buildStatusFilter() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Status',

          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),

        ),

        const SizedBox(height: 8),

        SingleChildScrollView(

          scrollDirection: Axis.horizontal,

          child: Row(

            children: ['All', 'Active', 'Inactive'].map((status) {

              return Padding(

                padding: const EdgeInsets.only(right: 8),

                child: FilterChip(

                  label: Text(status),

                  selected: _selectedStatusFilter == status,

                  onSelected: (selected) {

                    setState(() {

                      _selectedStatusFilter = status;

                      _applyFilters();

                    });

                  },

                  selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),

                  labelStyle: TextStyle(

                    color: _selectedStatusFilter == status ? AppColors.primaryGreen : AppColors.textDark,

                  ),

                ),

              );

            }).toList(),

          ),

        ),

      ],

    );

  }



  Widget _buildUserList() {

    return Consumer<AdminProvider>(

      builder: (context, adminProvider, child) {

        if (adminProvider.isLoading) {

          return const Center(child: CircularProgressIndicator());

        }



        if (adminProvider.users.isEmpty) {

          return Container(

            padding: const EdgeInsets.all(32),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: Colors.grey.shade200),

            ),

            child: Column(

              children: [

                Icon(Icons.people_outline, size: 48, color: AppColors.textLight),

                const SizedBox(height: 16),

                const Text(

                  'No users found',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),

                ),

                const SizedBox(height: 8),

                const Text(

                  'Try adjusting your filters or add new users',

                  style: TextStyle(fontSize: 12, color: AppColors.textLight),

                ),

              ],

            ),

          );

        }



        return Column(

          children: adminProvider.users.map((user) => _buildUserCard(user)).toList(),

        );

      },

    );

  }



  Widget _buildUserCard(UserModel user) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.shade200),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              CircleAvatar(

                radius: 20,

                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),

                child: Text(

                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',

                  style: const TextStyle(

                    color: AppColors.primaryGreen,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      user.fullName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(

                        fontSize: 14,

                        fontWeight: FontWeight.bold,

                        color: AppColors.textDark,

                      ),

                    ),

                    Text(

                      user.email ?? 'No email',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(

                        fontSize: 12,

                        color: AppColors.textLight,

                      ),

                    ),

                  ],

                ),

              ),

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                decoration: BoxDecoration(

                  color: _getRoleColor(user.role).withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Text(

                  user.role,

                  style: TextStyle(

                    fontSize: 10,

                    fontWeight: FontWeight.bold,

                    color: _getRoleColor(user.role),

                  ),

                ),

              ),

              const SizedBox(width: 8),

              IconButton(

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(),

                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.errorRed),

                onPressed: () => _confirmDeleteUser(user),

              ),

            ],

          ),

          const SizedBox(height: 12),

          Row(

            children: [

              Icon(Icons.phone, size: 16, color: AppColors.textLight),

              const SizedBox(width: 4),

              Text(

                user.phone,

                style: TextStyle(

                  fontSize: 12,

                  color: AppColors.textLight,

                ),

              ),

              const Spacer(),

              Icon(Icons.access_time, size: 16, color: AppColors.textLight),

              const SizedBox(width: 4),

              Text(

                _formatDate(user.createdAt),

                style: TextStyle(

                  fontSize: 12,

                  color: AppColors.textLight,

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          Row(

            children: [

              Expanded(

                child: OutlinedButton.icon(

                  onPressed: () => _editUser(user),

                  icon: const Icon(Icons.edit, size: 16),

                  label: const Text('Edit', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),

                  style: OutlinedButton.styleFrom(

                    padding: const EdgeInsets.symmetric(horizontal: 0),

                    side: const BorderSide(color: AppColors.primaryGreen),

                    foregroundColor: AppColors.primaryGreen,

                  ),

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: ElevatedButton.icon(

                  onPressed: () => _toggleUserStatus(user),

                  icon: Icon(

                    user.isActive ? Icons.block : Icons.check_circle,

                    size: 16,

                  ),

                  label: Text(

                    user.isActive ? 'Deactivate' : 'Activate',

                    style: const TextStyle(fontSize: 12),

                    overflow: TextOverflow.ellipsis,

                  ),

                  style: ElevatedButton.styleFrom(

                    padding: const EdgeInsets.symmetric(horizontal: 0),

                    backgroundColor: user.isActive ? AppColors.errorRed : AppColors.successGreen,

                    foregroundColor: Colors.white,

                  ),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Color _getRoleColor(String role) {

    switch (role) {

      case 'Admin':

        return AppColors.primaryGreen;

      case 'Business Owner':

        return AppColors.primaryGreen;

      case 'Manager':

        return AppColors.primaryOrange;

      case 'Driver':

        return AppColors.primaryGreen;

      default:

        return AppColors.textLight;

    }

  }



  String _formatDate(DateTime date) {

    return '${date.day}/${date.month}/${date.year}';

  }



  void _applyFilters() {

    // Implementation for filtering users

    setState(() {

      _filteredUsers = [];

    });

  }



  void _editUser(UserModel user) {

    final nameController = TextEditingController(text: user.fullName);

    final emailController = TextEditingController(text: user.email);

    final phoneController = TextEditingController(text: user.phone);

    final roleController = TextEditingController(text: user.role);



    showDialog(

      context: context,

      builder: (BuildContext context) {

        return AlertDialog(

          title: Text('Edit User: ${user.fullName}'),

          content: SizedBox(

            width: 400,

            child: SingleChildScrollView(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),

                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),

                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),

                  TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role')),

                ],

              ),

            ),

          ),

          actions: [

            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

            ElevatedButton(

              onPressed: () async {

                final updatedUser = UserModel(

                  userId: user.userId,

                  fullName: nameController.text,

                  email: emailController.text,

                  phone: phoneController.text,

                  role: roleController.text,

                  businessId: user.businessId,

                  createdAt: user.createdAt,

                  isActive: user.isActive,

                  mustChangePassword: user.mustChangePassword,

                );



                final success = await context.read<AdminProvider>().updateUser(updatedUser);

                Navigator.pop(context);

                if (success) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(content: Text('User updated successfully')),

                  );

                }

              },

              child: const Text('Save'),

            ),

          ],

        );

      },

    );

  }



  Future<void> _toggleUserStatus(UserModel user) async {
    final success = await context.read<AdminProvider>().toggleUserStatus(user.userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(user.isActive ? 'User deactivated successfully' : 'User activated successfully')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update user status')));
    }
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
          content: Text('Are you sure you want to permanently delete user "${user.fullName}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await context.read<AdminProvider>().deleteUser(user.userId);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete user')));
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

