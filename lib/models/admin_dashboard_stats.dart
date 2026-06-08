class AdminDashboardStats {
  final int totalProducts;
  final int totalOrders;
  final int deliveredOrders;
  final double totalRevenue;
  final int outOfStockCount;
  final int totalUsers;

  AdminDashboardStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.totalRevenue,
    required this.outOfStockCount,
    required this.totalUsers,
  });
}
