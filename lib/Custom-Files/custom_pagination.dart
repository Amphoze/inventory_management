import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/utils.dart';

class CustomPaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int? totalCount;
  final double buttonSize;
  final TextEditingController pageController;
  final VoidCallback onFirstPage;
  final VoidCallback onLastPage;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final Function(int) onGoToPage;
  final VoidCallback onJumpToPage;
  final bool toShowGoToPageField;
  // final bool toShowTotal;

  const CustomPaginationFooter({
    super.key,
    required this.currentPage,
    this.toShowGoToPageField = true,
    required this.totalPages,
    this.totalCount,
    required this.buttonSize,
    required this.pageController,
    required this.onFirstPage,
    required this.onLastPage,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onGoToPage,
    required this.onJumpToPage,
    // this.toShowTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double arrowButtonSize = 20;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: currentPage > 1 ? onFirstPage : null,
                  iconSize: arrowButtonSize,
                  color: currentPage > 1 ? AppColors.primaryBlue : Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1 ? onPreviousPage : null,
                  iconSize: arrowButtonSize,
                  color: currentPage > 1 ? AppColors.primaryBlue : Colors.grey,
                ),
                ..._buildPageButtons(currentPage - 1, totalPages, buttonSize), // Pass currentPage - 1 for zero-based
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages ? onNextPage : null,
                  iconSize: arrowButtonSize,
                  color: currentPage < totalPages ? AppColors.primaryBlue : Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: currentPage < totalPages ? onLastPage : null,
                  iconSize: arrowButtonSize,
                  color: currentPage < totalPages ? AppColors.primaryBlue : Colors.grey,
                ),
              ],
            ),
            // const Spacer(),

            if (totalCount != null)
              Utils.richText('Total: ', totalCount.toString(), fontSize: 16),

            if (toShowGoToPageField)
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 30,
                    child: TextField(
                      controller: pageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: 'Go to Page', border: OutlineInputBorder()),
                      onSubmitted: (value) => onJumpToPage,
                    ),
                  ),
                  Text(
                    ' / $totalPages',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onJumpToPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('Go'),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPageButtons(int currentPage, int totalPages, double buttonSize) {
    List<Widget> buttons = [];

    // Calculate the range of pages to display
    int startPage = currentPage - 2 < 0 ? 0 : currentPage - 2;
    int endPage = currentPage + 2 >= totalPages ? totalPages - 1 : currentPage + 2;

    // Adjust startPage to ensure 5 buttons are shown
    if (endPage - startPage < 4) {
      startPage = endPage - 4 < 0 ? 0 : endPage - 4;
    }

    // Generate the page buttons
    for (int i = startPage; i <= endPage; i++) {
      bool isCurrentPage = i == currentPage;
      buttons.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          child: ElevatedButton(
            onPressed: () => onGoToPage(i + 1),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(buttonSize * 1.9, buttonSize),
              padding: const EdgeInsets.symmetric(vertical: 4),
              backgroundColor: isCurrentPage ? AppColors.primaryBlue : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: isCurrentPage ? 18 : 13,
                color: isCurrentPage ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }
}
