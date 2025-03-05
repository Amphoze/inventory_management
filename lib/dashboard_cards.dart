import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Widgets/percent_dashboard_card.dart';

class DashboardCards extends StatefulWidget {
  final DateTime? date;
  final bool? isSuperAdmin;
  final bool? isAdmin;
  final bool? isConfirmer;
  final bool? isBooker;
  final bool? isAccounts;
  final bool? isPicker;
  final bool? isPacker;
  final bool? isChecker;
  final bool? isRacker;
  final bool? isManifest;
  final bool? isOutbound;

  const DashboardCards({
    super.key,
    required this.date,
    this.isSuperAdmin,
    this.isAdmin,
    this.isConfirmer,
    this.isBooker,
    this.isAccounts,
    this.isPicker,
    this.isPacker,
    this.isChecker,
    this.isRacker,
    this.isManifest,
    this.isOutbound,
  });

  @override
  _DashboardCardsState createState() => _DashboardCardsState();
}

class _DashboardCardsState extends State<DashboardCards> {
  final PageController _pageController = PageController();
  final int _numberOfPages = 5;

  @override
  void initState() {
    super.initState();

    log('date: ${widget.date}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetch();
    });

    // Provider.of<DashboardProvider>(context, listen: false)
    //     .fetchDoneData(currentDate);
  }

  Future<void> fetch() async {
    String currentDate = DateTime.now().toIso8601String().substring(0, 10);
    await Provider.of<DashboardProvider>(context, listen: false).fetchAllData(currentDate);
  }

  void _scrollLeft() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_pageController.page! < _numberOfPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String calculatePercentageChange(double today, double yesterday) {
    if (yesterday == 0) {
      return '0%';
    }
    double change = ((today - yesterday) / yesterday) * 100;
    return '${change.toStringAsFixed(2)}%';
  }

  // Helper method to calculate color based on change
  Color calculateChangeColor(double today, double yesterday) {
    return today < yesterday ? AppColors.cardsred : AppColors.cardsgreen;
  }

  bool isToday(DateTime date) {
    log('date: $date');
    log('date: ${widget.date}');
    // if(widget.date == null) return true;
    DateTime today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 800;

        double threeCardWidth = isSmallScreen ? constraints.maxWidth * 0.9 : (constraints.maxWidth - 32) / 3;
        double fiveCardWidth = isSmallScreen ? constraints.maxWidth * 0.8 / 5 : (constraints.maxWidth - 32) / 5;
        double cardHeight = isSmallScreen ? 140 : 150;

        var dashboardProvider = Provider.of<DashboardProvider>(context);
        var dashboardData = dashboardProvider.dashboardData;
        var doneData = dashboardProvider.doneData;

        return Column(
          children: [
            if (dashboardProvider.isLoading)
              const CircularProgressIndicator() // Show loader when data is loading
            else if (dashboardProvider.errorMessage != null)
              Text('Error: ${dashboardProvider.errorMessage}') // Show error if there is one
            else if (dashboardData != null) ...[
              // if (widget.isSuperAdmin == true) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    // Gross Revenue
                    DashboardCard(
                      title: isToday(widget.date!) ? "Today's Gross Revenue" : "Gross Revenue",
                      value: '₹${dashboardData.totalAmountToday.toStringAsFixed(2)}',
                      subtitle: 'Yesterday: ₹${dashboardData.totalAmountYesterday}',
                      percentageChange:
                          calculatePercentageChange(dashboardData.totalAmountToday as double, dashboardData.totalAmountYesterday as double),
                      changeColor:
                          calculateChangeColor(dashboardData.totalAmountToday as double, dashboardData.totalAmountYesterday as double),
                      chartData: const [1.0, 0.9, 0.8, 0.7],
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    // Orders
                    DashboardCard(
                      title: isToday(widget.date!) ? "Today's Orders" : "Orders",
                      value: '${dashboardData.totalOrderToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.totalOrderYesterday}',
                      // Dynamic subtitle from API
                      percentageChange:
                          calculatePercentageChange(dashboardData.totalOrderToday as double, dashboardData.totalOrderYesterday as double),
                      // Calculate percentage change
                      changeColor:
                          calculateChangeColor(dashboardData.totalOrderToday as double, dashboardData.totalOrderYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    // RTO-Delivered %
                    PercentDashboardCard(width: threeCardWidth, height: cardHeight),
                  ],
                ),
                const Divider(
                  height: 30,
                ),
              // ],
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  // Failed Orders
                  DashboardCard(
                    title: "Failed Orders",
                    value: '${dashboardData.failedOrdersToday}',
                    // Dynamic value from API
                    subtitle: 'Yesterday: ${dashboardData.failedOrdersYesterday}',
                    // Dynamic subtitle from API
                    percentageChange:
                        calculatePercentageChange(dashboardData.failedOrdersToday as double, dashboardData.failedOrdersYesterday as double),
                    // Calculate percentage change
                    changeColor:
                        calculateChangeColor(dashboardData.failedOrdersToday as double, dashboardData.failedOrdersYesterday as double),
                    // Dynamic color based on increase/decrease
                    chartData: const [1.0, 0.95, 0.85, 0.7],
                    // Customize as needed
                    width: threeCardWidth,
                    height: cardHeight,
                  ),
                  if (widget.isOutbound == true || widget.isAdmin == true || widget.isSuperAdmin == true) ...[
                    DashboardCard(
                      title: "Ready to Outbound Orders",
                      value: '${dashboardData.readyToOutBoundToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.readyToOutBoundYesterday}',
                      // Dynamic subtitle from API
                      percentageChange: calculatePercentageChange(
                          dashboardData.readyToOutBoundToday as double, dashboardData.readyToOutBoundYesterday as double),
                      // Calculate percentage change
                      changeColor: calculateChangeColor(
                          dashboardData.readyToOutBoundToday as double, dashboardData.readyToOutBoundYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    DashboardCard(
                      title: "Outbound Orders",
                      value: '${doneData!.outBoundToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${doneData.outBoundYesterday}',
                      // Dynamic subtitle
                      percentageChange: calculatePercentageChange(
                        doneData.outBoundToday as double,
                        doneData.outBoundYesterday as double,
                      ),
                      changeColor: calculateChangeColor(
                        doneData.outBoundToday as double,
                        doneData.outBoundYesterday as double,
                      ),
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Example chart data
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                  ],
                  if (widget.isConfirmer == true || widget.isAdmin == true || widget.isSuperAdmin == true) ...[
                    DashboardCard(
                      title: "Ready to Confirm Orders",
                      value: '${dashboardData.readyToConfirmedOrdersToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.readyToConfirmedOrdersYesterday}',
                      // Dynamic subtitle from API
                      percentageChange: calculatePercentageChange(
                          dashboardData.readyToConfirmedOrdersToday as double, dashboardData.readyToConfirmedOrdersYesterday as double),
                      // Calculate percentage change
                      changeColor: calculateChangeColor(
                          dashboardData.readyToConfirmedOrdersToday as double, dashboardData.readyToConfirmedOrdersYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    DashboardCard(
                      title: "Confirmed Orders",
                      value: '${doneData!.confirmedOrderToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${doneData.confirmedOrderYesterday}',
                      // Dynamic subtitle
                      percentageChange: calculatePercentageChange(
                        doneData.confirmedOrderToday as double,
                        doneData.confirmedOrderYesterday as double,
                      ),
                      changeColor: calculateChangeColor(
                        doneData.confirmedOrderToday as double,
                        doneData.confirmedOrderYesterday as double,
                      ),
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Example chart data
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                  ],
                  if (widget.isAdmin == true || widget.isSuperAdmin == true) ...[
                    DashboardCard(
                      title: "Ready to HOD Approval",
                      value: '${dashboardData.readyToHodApprovalToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.readyToHodApprovalYesterday}',
                      // Dynamic subtitle from API
                      percentageChange: calculatePercentageChange(
                          dashboardData.readyToHodApprovalToday as double, dashboardData.readyToHodApprovalYesterday as double),
                      // Calculate percentage change
                      changeColor: calculateChangeColor(
                          dashboardData.readyToHodApprovalToday as double, dashboardData.readyToHodApprovalYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    DashboardCard(
                      title: "HOD Approval Orders",
                      value: '${doneData!.hodApprovalToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${doneData.hodApprovalYesterday}',
                      // Dynamic subtitle
                      percentageChange: calculatePercentageChange(
                        doneData.hodApprovalToday as double,
                        doneData.hodApprovalYesterday as double,
                      ),
                      changeColor: calculateChangeColor(
                        doneData.hodApprovalToday as double,
                        doneData.hodApprovalYesterday as double,
                      ),
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                  ],
                  if (widget.isAccounts == true || widget.isAdmin == true || widget.isSuperAdmin == true) ...[
                    DashboardCard(
                      title: "Ready to Account Orders",
                      value: '${dashboardData.readyToAccountOrdersToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.readyToAccountOrdersYesterday}',
                      // Dynamic subtitle from API
                      percentageChange: calculatePercentageChange(
                          dashboardData.readyToAccountOrdersToday as double, dashboardData.readyToAccountOrdersYesterday as double),
                      // Calculate percentage change
                      changeColor: calculateChangeColor(
                          dashboardData.readyToAccountOrdersToday as double, dashboardData.readyToAccountOrdersYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    DashboardCard(
                      title: "Account Orders",
                      value: '${doneData!.accountOrderToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${doneData.accountOrderYesterday}',
                      // Dynamic subtitle
                      percentageChange: calculatePercentageChange(
                        doneData.accountOrderToday as double,
                        doneData.accountOrderYesterday as double,
                      ),
                      changeColor: calculateChangeColor(
                        doneData.accountOrderToday as double,
                        doneData.accountOrderYesterday as double,
                      ),
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                  ],
                  if (widget.isBooker == true || widget.isAdmin == true || widget.isSuperAdmin == true) ...[
                    DashboardCard(
                      title: "Ready to Book Orders",
                      value: '${dashboardData.readyToBookedOrdersToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${dashboardData.readyToBookedOrdersYesterday}',
                      // Dynamic subtitle from API
                      percentageChange: calculatePercentageChange(
                          dashboardData.readyToBookedOrdersToday as double, dashboardData.readyToBookedOrdersYesterday as double),
                      // Calculate percentage change
                      changeColor: calculateChangeColor(
                          dashboardData.readyToBookedOrdersToday as double, dashboardData.readyToBookedOrdersYesterday as double),
                      // Dynamic color based on increase/decrease
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      // Customize as needed
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                    DashboardCard(
                      title: "Booked Orders",
                      value: '${doneData!.bookedOrderToday}',
                      // Dynamic value from API
                      subtitle: 'Yesterday: ${doneData.bookedOrderYesterday}',
                      // Dynamic subtitle
                      percentageChange: calculatePercentageChange(
                        doneData.bookedOrderToday as double,
                        doneData.bookedOrderYesterday as double,
                      ),
                      changeColor: calculateChangeColor(
                        doneData.bookedOrderToday as double,
                        doneData.bookedOrderYesterday as double,
                      ),
                      chartData: const [1.0, 0.95, 0.85, 0.7],
                      width: threeCardWidth,
                      height: cardHeight,
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String percentageChange;
  final Color changeColor;
  final List<double> chartData;
  final double width;
  final double height;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.percentageChange,
    required this.changeColor,
    required this.chartData,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue.withValues(alpha: 0.9),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Value Section
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),

            const Spacer(),

            // Bottom Info Section
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          double.parse(percentageChange.replaceAll('%', '')) >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          percentageChange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ],
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