import 'package:flutter/material.dart';
import 'package:inventory_management/product_master.dart';
import 'package:inventory_management/provider/category_provider.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Custom-Files/product_master_card.dart';
import 'Custom-Files/utils.dart';

class CategoryProductsPage extends StatefulWidget {
  final String category;
  const CategoryProductsPage({super.key, required this.category});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late CategoryProvider provider;
  final TextEditingController pageController = TextEditingController();

  @override
  void initState() {
    provider = context.read<CategoryProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchCategoryProducts(widget.category);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, pro, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.category),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: RichText(
                  text: TextSpan(
                    text: 'Total Products: ',
                    children: [
                      TextSpan(
                        text: pro.totalCategoryProducts.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                    style: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                  ),
                ),
              )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: pro.isFetchingProducts
                    ? const Center(
                        child: LoadingAnimation(
                          icon: Icons.shopping_cart,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    : pro.categoryProducts.isEmpty
                        ? Center(
                            child: RichText(
                              text: TextSpan(
                                  text: 'No Products found for: ',
                                  children: [
                                    TextSpan(
                                      text: widget.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  style: const TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView.builder(
                              itemCount: pro.categoryProducts.length,
                              itemBuilder: (BuildContext context, int index) {
                                final product = pro.categoryProducts[index];
                                return ProductMasterCard(product: product);
                              },
                            ),
                          ),
              ),
              CustomPaginationFooter(
                currentPage: pro.currentProductsPage,
                totalPages: pro.totalProductsPages,
                buttonSize: 30,
                pageController: pageController,
                onFirstPage: () {
                  pro.fetchCategoryProducts(widget.category, page: 1);
                },
                onLastPage: () {
                  pro.fetchCategoryProducts(widget.category, page: pro.totalProductsPages);
                },
                onNextPage: () {
                  if (pro.currentProductsPage < pro.totalProductsPages) {
                    pro.fetchCategoryProducts(widget.category, page: pro.currentProductsPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (pro.currentProductsPage > 1) {
                    pro.fetchCategoryProducts(widget.category, page: pro.currentProductsPage - 1);
                  }
                },
                onGoToPage: (page) {
                  if (page > 0 && page <= pro.totalProductsPages) {
                    pro.fetchCategoryProducts(widget.category, page: page);
                  }
                },
                onJumpToPage: () {
                  final int? page = int.tryParse(pageController.text);

                  if (page == null || page < 1 || page > pro.totalProductsPages) {
                    Utils.showSnackBar(context, 'Please enter a valid page number between 1 and ${pro.totalProductsPages}.');
                    return;
                  }

                  pro.fetchCategoryProducts(widget.category, page: page);
                  pageController.clear();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
