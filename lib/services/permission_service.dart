class PermissionService {
  // ============================================================
  // ROLE CHECKS
  // ============================================================
  static bool isSuperAdmin(String? role) => role == 'superadmin';

  static bool isAdmin(String? role) =>
      role == 'admin' || role == 'superadmin';

  static bool isTeknisi(String? role) => role == 'teknisi';

  static bool isAdminGudang(String? role) => role == 'admin_gudang';

  static bool isUser(String? role) => role == 'user';

  // ============================================================
  // TICKET PERMISSIONS
  // ============================================================
  static bool canCreateTicket(String? role) =>
      isAdmin(role) || isUser(role);

  static bool canDeleteTicket(String? role) => isAdmin(role);

  static bool canApproveTicket(String? role) => isAdmin(role);

  static bool canUpdateTicketStatus(String? role) =>
      isAdmin(role) || isTeknisi(role);

  static bool canAddComment(String? role) => true;

  static bool canSeeCustomerHistory(String? role) =>
      isAdmin(role) || isUser(role);

  static bool canSeeTicketPoints(String? role) => isAdmin(role);

  // Status yang bisa dipilih teknisi
  static List<String> teknisiAllowedStatuses() =>
      ['in_progress', 'pending', 'resolved'];

  // ============================================================
  // WAREHOUSE PERMISSIONS
  // ============================================================
  static bool canSeeWarehouse(String? role) =>
      isAdmin(role) || isAdminGudang(role);

  static bool canAddStock(String? role) =>
      isAdmin(role) || isAdminGudang(role);

  static bool canReduceStock(String? role) =>
      isAdmin(role) || isAdminGudang(role);

  static bool canApproveRequest(String? role) =>
      isAdmin(role) || isAdminGudang(role);

  static bool canCreateRequest(String? role) =>
      isAdmin(role) || isAdminGudang(role) || isTeknisi(role);

  static bool canManageUsers(String? role) => isAdmin(role);

  // ============================================================
  // NAVIGATION PERMISSIONS
  // ============================================================
  static bool canSeeLeaderboard(String? role) => !isTeknisi(role);

  // ============================================================
  // HELPERS
  // ============================================================
  static String getRoleLabel(String? role) {
    switch (role) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'teknisi':
        return 'Teknisi';
      case 'admin_gudang':
        return 'Admin Gudang';
      case 'user':
        return 'User';
      default:
        return role ?? '-';
    }
  }

  static int getRoleColor(String? role) {
    switch (role) {
      case 'superadmin':
        return 0xFF7c3aed;
      case 'admin':
        return 0xFFdc2626;
      case 'teknisi':
        return 0xFF2563eb;
      case 'admin_gudang':
        return 0xFF16a34a;
      case 'user':
        return 0xFF64748b;
      default:
        return 0xFF64748b;
    }
  }
}