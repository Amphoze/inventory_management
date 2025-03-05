import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/category_products_page.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final bool isSmallScreen;
  final double borderRadius;
  final double elevation;
  final Color cardColor;
  final Color shadowColor;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSmallScreen,
    this.borderRadius = 16.0,
    this.elevation = 3.0,
    this.cardColor = Colors.white,
    this.shadowColor = Colors.black26,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = isSmallScreen ? 70.0 : 60.0;
    final EdgeInsets cardPadding =
        isSmallScreen ? const EdgeInsets.all(12.0) : const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CategoryProductsPage(category: category)));
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: cardHeight,
            maxHeight: cardHeight,
          ),
          child: Material(
            elevation: elevation,
            shadowColor: shadowColor,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.8),
                    AppColors.lightBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: cardPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     // Add your action here
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.white,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 20.0,
                      //       vertical: 12.0,
                      //     ),
                      //   ),
                      //   child: Text(
                      //     'Action',
                      //     style: TextStyle(
                      //       fontSize: isSmallScreen ? 14 : 16,
                      //       color: AppColors.primaryBlue,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
