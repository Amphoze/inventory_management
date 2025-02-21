import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_card.dart';
import 'package:inventory_management/model/manifest_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/manifest_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

class ManifestSection extends StatefulWidget {
  const ManifestSection({super.key});

  @override
  State<ManifestSection> createState() => _ManifestSectionState();
}

class _ManifestSectionState extends State<ManifestSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManifestProvider>(context, listen: false).fetchCreatedManifests(1);
    });
    Provider.of<ManifestProvider>(context, listen: false).textEditingController.clear();
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<ManifestProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // String? selectedCourier;
    return Consumer<ManifestProvider>(
      builder: (context, manifestProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 35,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(183, 6, 90, 216),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Search by Order ID',
                          hintStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12.0),
                        ),
                        onChanged: (query) {
                          // Trigger a rebuild to show/hide the search button
                          setState(() {
                            // Update search focus
                          });
                          if (query.isEmpty) {
                            // Reset to all orders if search is cleared
                            manifestProvider.fetchCreatedManifests(manifestProvider.currentPage);
                          }
                        },
                        onTap: () {
                          setState(() {
                            // Mark the search field as focused
                          });
                        },
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            manifestProvider.searchOrders(query);
                          }
                        },
                        onEditingComplete: () {
                          // Mark it as not focused when done
                          FocusScope.of(context).unfocus(); // Dismiss the keyboard
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: _searchController.text.isNotEmpty ? _onSearchButtonPressed : null,
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: manifestProvider.isRefreshingOrders
                          ? null
                          : () async {
                              manifestProvider.fetchCreatedManifests(manifestProvider.currentPage);
                            },
                      child: manifestProvider.isRefreshingOrders
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Refresh',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // Decreased space here
              _buildTableHeader(manifestProvider.manifests.length, manifestProvider),
              const SizedBox(height: 4), // New space for alignment
              Expanded(
                child: Stack(
                  children: [
                    if (manifestProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.star_border_outlined,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (manifestProvider.manifests.isEmpty)
                      const Center(
                        child: Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: manifestProvider.manifests.length,
                        itemBuilder: (context, index) {
                          final manifest = manifestProvider.manifests[index];
                          return Column(
                            children: [
                              _buildManifest(manifest, index, manifestProvider),
                              const Divider(thickness: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage: manifestProvider.currentPage, // Ensure correct currentPage
                totalPages: manifestProvider.totalPages,
                buttonSize: 30,
                pageController: manifestProvider.textEditingController,
                onFirstPage: () {
                  manifestProvider.goToPage(1);
                },
                onLastPage: () {
                  manifestProvider.goToPage(manifestProvider.totalPages);
                },
                onNextPage: () {
                  if (manifestProvider.currentPage < manifestProvider.totalPages) {
                    print('Navigating to page: ${manifestProvider.currentPage + 1}');
                    manifestProvider.goToPage(manifestProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (manifestProvider.currentPage > 1) {
                    print('Navigating to page: ${manifestProvider.currentPage - 1}');
                    manifestProvider.goToPage(manifestProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  manifestProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(manifestProvider.textEditingController.text);
                  if (page != null && page > 0 && page <= manifestProvider.totalPages) {
                    manifestProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, ManifestProvider manifestProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          buildHeader('ORDERS', '', flex: 9), // Increased flex
          buildHeader('ID', '(Delivery Partner)', flex: 3), // Decreased flex for better alignment
          // buildHeader('CONFIRM', flex: 3),
        ],
      ),
    );
  }

  Widget buildHeader(String title, String subtitle, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
          child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          if (subtitle != '')
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
        ],
      )),
    );
  }

  Widget _buildManifest(Manifest manifest, int index, ManifestProvider manifestProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Increased vertical space for order cards
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: manifest.orders.length,
                  itemBuilder: (context, index) {
                    return OrderCard(order: manifest.orders[index]);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          buildCell(
            Column(
              children: [
                Text(
                  manifest.manifestId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
                Text(
                  "(${manifest.deliveryPartner})",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            flex: 1,
          ),
        ],
      ),
    );
  }

  Widget buildCell(Widget content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Center(child: content),
      ),
    );
  }
}
