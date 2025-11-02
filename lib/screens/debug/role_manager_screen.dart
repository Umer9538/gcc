import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/test_user_helper.dart';
import '../../constants/app_constants.dart';

/// DEBUG SCREEN - Remove before production deployment
/// This screen allows you to easily change user roles for testing
class RoleManagerScreen extends StatefulWidget {
  const RoleManagerScreen({super.key});

  @override
  State<RoleManagerScreen> createState() => _RoleManagerScreenState();
}

class _RoleManagerScreenState extends State<RoleManagerScreen> {
  List<String> _currentRoles = [];
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email;
      _currentRoles = await TestUserHelper.getCurrentUserRoles();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateRole(List<String> newRoles) async {
    setState(() => _isLoading = true);

    await TestUserHelper.updateCurrentUserRole(newRoles);
    await _loadCurrentUser();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Role updated to: ${newRoles.join(", ")}'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🔧 Role Manager (DEBUG)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Card
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'This is a DEBUG tool. Remove before production deployment!',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current User Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 20, color: AppColors.primaryColor),
                              const SizedBox(width: 8),
                              Text(_userEmail ?? 'Not logged in'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 20, color: AppColors.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Roles: ${_currentRoles.isEmpty ? 'None' : _currentRoles.join(", ")}',
                                style: TextStyle(
                                  color: _currentRoles.isEmpty ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role Selection
                  const Text(
                    'Select Role',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Role
                  _buildRoleCard(
                    title: 'Admin',
                    description: 'Full access - Can create announcements, manage users, etc.',
                    icon: Icons.admin_panel_settings,
                    color: Colors.red,
                    onTap: () => _updateRole(['admin']),
                    isActive: _currentRoles.contains('admin'),
                  ),
                  const SizedBox(height: 12),

                  // Manager Role
                  _buildRoleCard(
                    title: 'Manager',
                    description: 'Can create announcements, manage team, view reports',
                    icon: Icons.business_center,
                    color: Colors.blue,
                    onTap: () => _updateRole(['manager']),
                    isActive: _currentRoles.contains('manager'),
                  ),
                  const SizedBox(height: 12),

                  // HR Manager Role
                  _buildRoleCard(
                    title: 'HR Manager',
                    description: 'Manage employees, view directory, handle documents',
                    icon: Icons.people,
                    color: Colors.purple,
                    onTap: () => _updateRole(['hr']),
                    isActive: _currentRoles.contains('hr'),
                  ),
                  const SizedBox(height: 12),

                  // Employee Role
                  _buildRoleCard(
                    title: 'Employee',
                    description: 'Basic access - View meetings, messages, documents',
                    icon: Icons.person,
                    color: Colors.green,
                    onTap: () => _updateRole(['employee']),
                    isActive: _currentRoles.contains('employee'),
                  ),
                  const SizedBox(height: 12),

                  // Multi-role: Admin + Manager
                  _buildRoleCard(
                    title: 'Admin + Manager',
                    description: 'Combined permissions of both roles',
                    icon: Icons.star,
                    color: Colors.orange,
                    onTap: () => _updateRole(['admin', 'manager']),
                    isActive: _currentRoles.contains('admin') && _currentRoles.contains('manager'),
                  ),
                  const SizedBox(height: 32),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadCurrentUser,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh User Info'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'How to Use',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('1. Select a role above'),
                          const Text('2. Wait for confirmation message'),
                          const Text('3. Restart the app (hot restart)'),
                          const Text('4. Navigate to Announcements'),
                          const Text('5. You should now see the "+" button'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Card(
      elevation: isActive ? 4 : 1,
      color: isActive ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? color : null,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, color: color, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
