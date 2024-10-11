class DashboardData {
  final num totalOrderToday;
  final num totalOrderYesterday;
  final num totalAmountToday;
  final num totalAmountYesterday;

  DashboardData({
    required this.totalOrderToday,
    required this.totalOrderYesterday,
    required this.totalAmountToday,
    required this.totalAmountYesterday,
  });

  // Factory constructor to create a DashboardData instance from JSON
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalOrderToday: json['TotalOrderToday'],
      totalOrderYesterday: json['TotalOrderyesterday'],
      totalAmountToday: json['TotalAmountToday'],
      totalAmountYesterday: json['TotalAmountYesterday'],
    );
  }
}
