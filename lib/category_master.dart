import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/categoryCard.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/provider/category_provider.dart';

class CategoryMasterPage extends StatefulWidget {
  @override
  _CategoryMasterPageState createState() => _CategoryMasterPageState();
}

class _CategoryMasterPageState extends State<CategoryMasterPage> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    categoryProvider.fetchAllCategories();

    categoryProvider.searchController.addListener(() {
      if (categoryProvider.isSearchMode) {
        _onSearchChanged(categoryProvider.searchController.text);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      Provider.of<CategoryProvider>(context, listen: false)
          .filterCategories(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isSmallScreen
                ? Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      _buildButton(
                        text: categoryProvider.isCreatingCategory
                            ? 'Cancel'
                            : 'Create',
                        color: AppColors.tealcolor,
                        icon: categoryProvider.isCreatingCategory
                            ? Icons.cancel
                            : Icons.add,
                        onTap: categoryProvider.toggleCreateCategoryMode,
                      ),
                      if (!categoryProvider.isCreatingCategory) ...[
                        _buildButton(
                          text: categoryProvider.isSearchMode
                              ? 'Cancel'
                              : 'Search',
                          color: AppColors.primaryBlue,
                          icon: categoryProvider.isSearchMode
                              ? Icons.cancel
                              : Icons.search,
                          onTap: categoryProvider.toggleSearchMode,
                        ),
                      ],
                      if (categoryProvider.isCreatingCategory)
                        Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller:
                                      categoryProvider.categoryNameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Category Name'),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: categoryProvider.createCategory,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                      if (categoryProvider.isSearchMode &&
                          !categoryProvider.isCreatingCategory)
                        Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            width: 150,
                            child: TextField(
                              controller: categoryProvider.searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search Category by Name',
                                suffixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      _buildButton(
                        text: "Refresh",
                        color: AppColors.primaryBlue,
                        icon: Icons.refresh,
                        onTap: () {
                          // Start fetching categories when the button is tapped
                          categoryProvider.fetchAllCategories();
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildButton(
                        text: categoryProvider.isCreatingCategory
                            ? 'Cancel'
                            : 'Create',
                        color: AppColors.tealcolor,
                        icon: categoryProvider.isCreatingCategory
                            ? Icons.cancel
                            : Icons.add,
                        onTap: categoryProvider.toggleCreateCategoryMode,
                      ),
                      const SizedBox(width: 16.0),
                      if (!categoryProvider.isCreatingCategory) ...[
                        _buildButton(
                          text: categoryProvider.isSearchMode
                              ? 'Cancel'
                              : 'Search',
                          color: AppColors.primaryBlue,
                          icon: categoryProvider.isSearchMode
                              ? Icons.cancel
                              : Icons.search,
                          onTap: categoryProvider.toggleSearchMode,
                        ),
                      ],
                      const SizedBox(width: 16.0),
                      if (categoryProvider.isCreatingCategory)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller:
                                      categoryProvider.categoryNameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Category Name'),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: categoryProvider.createCategory,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                      if (categoryProvider.isSearchMode &&
                          !categoryProvider.isCreatingCategory)
                        Expanded(
                          child: SizedBox(
                            width: 200,
                            child: TextField(
                              controller: categoryProvider.searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search Category by Name',
                                suffixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      _buildButton(
                        text: "Refresh",
                        color: AppColors.primaryBlue,
                        icon: Icons.refresh,
                        onTap: () {
                          // Start fetching categories when the button is tapped
                          categoryProvider.fetchAllCategories();
                        },
                      ),
                    ],
                  ),
            const SizedBox(height: 24.0),

            // Display Loader when fetching data
            if (categoryProvider.isFetching)
              const Center(
                child: LoadingAnimation(
                  icon: Icons.category,
                  beginColor: Color.fromRGBO(189, 189, 189, 1),
                  endColor: AppColors.primaryBlue,
                  size: 80.0,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    return CategoryCard(
                      category: categoryProvider.categories[index],
                      isSmallScreen: isSmallScreen,
                      cardColor: AppColors.white,
                      shadowColor: AppColors.shadowblack1,
                      elevation: 3,
                      borderRadius: 12,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CustomButton(
      width: 120,
      height: 40,
      onTap: onTap,
      color: color,
      textColor: AppColors.white,
      fontSize: 16,
      text: text,
      borderRadius: BorderRadius.circular(12),
      prefixIcon: Icon(icon, size: 18, color: AppColors.white),
    );
  }
}
