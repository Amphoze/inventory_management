class DashboardData {
  final num totalOrderToday;
  final num totalOrderYesterday;
  final num totalAmountToday;
  final num totalAmountYesterday;
  final num failedOrdersToday;
  final num failedOrdersYesterday;
  final num readyToConfirmedOrdersToday;
  final num readyToConfirmedOrdersYesterday;
  final num readyToAccountOrdersToday;
  final num readyToAccountOrdersYesterday;
  final num readyToBookedOrdersToday;
  final num readyToBookedOrdersYesterday;
  final num readyToHodApprovalToday;
  final num readyToHodApprovalYesterday;

  final num confirmedOrderToday;
  final num confirmedOrderYesterday;
  final num bookedOrderToday;
  final num bookedOrderYesterday;
  final num accountOrderToday;
  final num accountOrderYesterday;
  final num outBoundToday;
  final num outBoundYesterday;
  final num hodApprovalToday;
  final num hodApprovalYesterday;

  DashboardData({
    required this.totalOrderToday,
    required this.totalOrderYesterday,
    required this.totalAmountToday,
    required this.totalAmountYesterday,
    required this.failedOrdersToday,
    required this.failedOrdersYesterday,
    required this.readyToConfirmedOrdersToday,
    required this.readyToConfirmedOrdersYesterday,
    required this.readyToAccountOrdersToday,
    required this.readyToAccountOrdersYesterday,
    required this.readyToBookedOrdersToday,
    required this.readyToBookedOrdersYesterday,
    required this.readyToHodApprovalToday,
    required this.readyToHodApprovalYesterday,
    required this.confirmedOrderToday,
    required this.confirmedOrderYesterday,
    required this.bookedOrderToday,
    required this.bookedOrderYesterday,
    required this.accountOrderToday,
    required this.accountOrderYesterday,
    required this.outBoundToday,
    required this.outBoundYesterday,
    required this.hodApprovalToday,
    required this.hodApprovalYesterday,
  });

  //   {
//     "ConfirmedOrderToday": 59,
//     "ConfirmedOrderYesterday": 42,
//     "bookedOrderToday": 53,
//     "bookedOrderYesterday": 32,
//     "accountOrderToday": 173,
//     "accountOrderYesterday": 164,
//     "outBoundToday": 132,
//     "outBoundYesterday": 167,
//     "HODApprovalToday": 0,
//     "HODApprovalYesterday": 0
// }

  // Factory constructor to create a DashboardData instance from JSON
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalOrderToday: json['TotalOrderToday'] ?? 0,
      totalOrderYesterday: json['TotalOrderyesterday'] ?? 0,
      totalAmountToday: json['TotalAmountToday'] ?? 0,
      totalAmountYesterday: json['TotalAmountYesterday'] ?? 0,
      /////////////////////////////////////////////////////////////////
      failedOrdersToday: json['FailedOrdersToday'] ?? 0,
      failedOrdersYesterday: json['FailedOrdersYesterday'] ?? 0,
      readyToConfirmedOrdersToday: json['readyToConfirmedOrdersToday'] ?? 0,
      readyToConfirmedOrdersYesterday:
          json['readyToConfirmedOrdersYesterday'] ?? 0,
      readyToAccountOrdersToday: json['readyToAccountOrdersToday'] ?? 0,
      readyToAccountOrdersYesterday: json['readyToAccountOrdersYesterday'] ?? 0,
      readyToBookedOrdersToday: json['readyToBookedOrdersToday'] ?? 0,
      readyToBookedOrdersYesterday: json['readyToBookedOrdersYesterday'] ?? 0,
      readyToHodApprovalToday: json['readyToHodApprovalToday'] ?? 0,
      readyToHodApprovalYesterday: json['readyToHodApprovalYesterday'] ?? 0,
      /////////////////////////////////////////////////////////////////
      confirmedOrderToday: json['ConfirmedOrderToday'] ?? 0,
      confirmedOrderYesterday: json['ConfirmedOrderYesterday'] ?? 0,
      bookedOrderToday: json['bookedOrderToday'] ?? 0,
      bookedOrderYesterday: json['bookedOrderYesterday'] ?? 0,
      accountOrderToday: json['accountOrderToday'] ?? 0,
      accountOrderYesterday: json['accountOrderYesterday'] ?? 0,
      outBoundToday: json['outBoundToday'] ?? 0,
      outBoundYesterday: json['outBoundYesterday'] ?? 0,
      hodApprovalToday: json['HODApprovalToday'] ?? 0,
      hodApprovalYesterday: json['HODApprovalYesterday'] ?? 0,
    );
  }
}
