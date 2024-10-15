import 'package:flutter/material.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/colors.dart';

class DashboardCards extends StatefulWidget {
  const DashboardCards({super.key});

  @override
  _DashboardCardsState createState() => _DashboardCardsState();
}

class _DashboardCardsState extends State<DashboardCards> {
  final PageController _pageController = PageController();
  final int _numberOfPages = 5;

  @override
  void initState() {
    super.initState();
    // Fetch the dashboard data with today's date when the page loads
    String currentDate = DateTime.now()
        .toIso8601String()
        .substring(0, 10); // Get 'yyyy-MM-dd' format
    Provider.of<DashboardProvider>(context, listen: false)
        .fetchDashboardData(currentDate);
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 800;

        double threeCardWidth = isSmallScreen
            ? constraints.maxWidth * 0.9
            : (constraints.maxWidth - 32) / 3;
        double fiveCardWidth = isSmallScreen
            ? constraints.maxWidth * 0.8 / 5
            : (constraints.maxWidth - 32) / 5;
        double cardHeight = isSmallScreen ? 140 : 150;

        var dashboardProvider = Provider.of<DashboardProvider>(context);
        var dashboardData = dashboardProvider.dashboardData;

        return Column(
          children: [
            if (dashboardProvider.isLoading)
              CircularProgressIndicator() // Show loader when data is loading
            else if (dashboardProvider.errorMessage != null)
              Text(
                  'Error: ${dashboardProvider.errorMessage}') // Show error if there is one
            else if (dashboardData != null)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  DashboardCard(
                    title: "Today's Gross Revenue",
                    value:
                        '₹${dashboardData.totalAmountToday}', // Dynamic value from API
                    subtitle:
                        'Yesterday: ₹${dashboardData.totalAmountYesterday}', // Dynamic subtitle from API
                    percentageChange: calculatePercentageChange(
                        dashboardData.totalAmountToday as double,
                        dashboardData.totalAmountYesterday
                            as double), // Calculate percentage change
                    changeColor: calculateChangeColor(
                        dashboardData.totalAmountToday as double,
                        dashboardData.totalAmountYesterday
                            as double), // Dynamic color based on increase/decrease
                    chartData: [1.0, 0.9, 0.8, 0.7], // You can customize this
                    width: threeCardWidth,
                    height: cardHeight,
                  ),
                  DashboardCard(
                    title: "Today's Orders",
                    value:
                        '${dashboardData.totalOrderToday}', // Dynamic value from API
                    subtitle:
                        'Yesterday: ${dashboardData.totalOrderYesterday}', // Dynamic subtitle from API
                    percentageChange: calculatePercentageChange(
                        dashboardData.totalOrderToday as double,
                        dashboardData.totalOrderYesterday
                            as double), // Calculate percentage change
                    changeColor: calculateChangeColor(
                        dashboardData.totalOrderToday as double,
                        dashboardData.totalOrderYesterday
                            as double), // Dynamic color based on increase/decrease
                    chartData: [1.0, 0.95, 0.85, 0.7], // Customize as needed
                    width: threeCardWidth,
                    height: cardHeight,
                  ),
                  // DashboardCard(
                  //   title: "Today's Return",
                  //   value: '₹0',
                  //   subtitle: 'Yesterday: ₹0',
                  //   percentageChange: '0%',
                  //   changeColor: AppColors.cardsgreen,
                  //   chartData: [1.0, 0.9, 0.85, 0.8],
                  //   width: threeCardWidth,
                  //   height: cardHeight,
                  // ),
                ],
              ),
            // const SizedBox(height: 16.0),
            // if (isSmallScreen)
            //   SizedBox(
            //     height: cardHeight + 50,
            //     child: Row(
            //       children: [
            //         IconButton(
            //           icon: const Icon(Icons.arrow_left),
            //           onPressed: _scrollLeft,
            //         ),
            //         Expanded(
            //           child: PageView(
            //             controller: _pageController,
            //             children: [
            //               DashboardCard(
            //                 title: 'Total Sub-Orders',
            //                 value: '30',
            //                 subtitle: 'Yesterday: 35',
            //                 percentageChange: '-14%',
            //                 changeColor: AppColors.cardsred,
            //                 chartData: const [1.0, 0.8, 0.7, 0.5],
            //                 width: fiveCardWidth,
            //                 height: cardHeight,
            //               ),
            //               DashboardCard(
            //                 title: 'Distinct SKU Sold',
            //                 value: '1,200',
            //                 subtitle: 'Yesterday: 1,500',
            //                 percentageChange: '-20%',
            //                 changeColor: AppColors.cardsred,
            //                 chartData: [1.0, 0.85, 0.75, 0.6],
            //                 width: fiveCardWidth,
            //                 height: cardHeight,
            //               ),
            //               DashboardCard(
            //                 title: 'Pending Orders',
            //                 value: '850',
            //                 subtitle: 'Yesterday: 950',
            //                 percentageChange: 'NA',
            //                 changeColor: AppColors.grey,
            //                 chartData: [1.0, 0.92, 0.85, 0.7],
            //                 width: fiveCardWidth,
            //                 height: cardHeight,
            //               ),
            //               DashboardCard(
            //                 title: 'Hold Orders',
            //                 value: '25%',
            //                 subtitle: 'Yesterday: 30%',
            //                 percentageChange: '-16%',
            //                 changeColor: AppColors.cardsred,
            //                 chartData: [1.0, 0.95, 0.85, 0.7],
            //                 width: fiveCardWidth,
            //                 height: cardHeight,
            //               ),
            //               DashboardCard(
            //                 title: 'Avg. Order Value',
            //                 value: '5',
            //                 subtitle: 'Yesterday: 5',
            //                 percentageChange: '0%',
            //                 changeColor: AppColors.grey,
            //                 chartData: [1.0, 1.0, 1.0, 1.0],
            //                 width: fiveCardWidth,
            //                 height: cardHeight,
            //               ),
            //             ],
            //           ),
            //         ),
            //         IconButton(
            //           icon: const Icon(Icons.arrow_right),
            //           onPressed: _scrollRight,
            //         ),
            //       ],
            //     ),
            //   )
            // else
            //   Wrap(
            //     spacing: 8.0,
            //     runSpacing: 8.0,
            //     alignment: WrapAlignment.start,
            //     children: [
            //       DashboardCard(
            //         title: 'Customers',
            //         value: '30',
            //         subtitle: 'Yesterday: 35',
            //         percentageChange: '-14%',
            //         changeColor: AppColors.cardsred,
            //         chartData: [1.0, 0.8, 0.7, 0.5],
            //         width: fiveCardWidth,
            //         height: cardHeight,
            //       ),
            //       DashboardCard(
            //         title: 'Likes',
            //         value: '1,200',
            //         subtitle: 'Yesterday: 1,500',
            //         percentageChange: '-20%',
            //         changeColor: AppColors.cardsred,
            //         chartData: [1.0, 0.85, 0.75, 0.6],
            //         width: fiveCardWidth,
            //         height: cardHeight,
            //       ),
            //       DashboardCard(
            //         title: 'Reviews',
            //         value: '850',
            //         subtitle: 'Yesterday: 950',
            //         percentageChange: '-11%',
            //         changeColor: AppColors.cardsred,
            //         chartData: [1.0, 0.92, 0.85, 0.7],
            //         width: fiveCardWidth,
            //         height: cardHeight,
            //       ),
            //       DashboardCard(
            //         title: 'Growth',
            //         value: '25%',
            //         subtitle: 'Yesterday: 30%',
            //         percentageChange: '-16%',
            //         changeColor: AppColors.cardsred,
            //         chartData: [1.0, 0.95, 0.85, 0.7],
            //         width: fiveCardWidth,
            //         height: cardHeight,
            //       ),
            //       DashboardCard(
            //         title: 'Settings',
            //         value: '5',
            //         subtitle: 'Yesterday: 5',
            //         percentageChange: '0%',
            //         changeColor: AppColors.grey,
            //         chartData: [1.0, 1.0, 1.0, 1.0],
            //         width: fiveCardWidth,
            //         height: cardHeight,
            //       ),
            //     ],
            //   ),
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
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              Text(
                percentageChange,
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
