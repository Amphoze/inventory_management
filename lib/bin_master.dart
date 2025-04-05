import 'package:flutter/material.dart';
import 'package:inventory_management/Api/bin_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/bin_products.dart';
import 'package:inventory_management/create_bin_page.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:provider/provider.dart';

class BinMasterPage extends StatefulWidget {
  const BinMasterPage({super.key});

  @override
  State<BinMasterPage> createState() => _BinMasterPageState();
}

class _BinMasterPageState extends State<BinMasterPage> {
  String? selectedBin;
  final _searchController = TextEditingController();

  void selectBin(String? binName) {
    setState(() {
      selectedBin = binName;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchWarehouses();
      Provider.of<BinApi>(context, listen: false).fetchBins(context);
      // getWarehouse();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BinApi>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.toShowBins)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search bins by product...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                      ),
                      onSubmitted: (value) {
                        provider.seearchBinsByProduct(context, value);
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          provider.fetchBins(context);
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh Bins',
                    onPressed: () {
                      provider.fetchBins(context);
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBinPage())),
                    child: const Text('Create Bin'),
                  ),
                ],
              ),
            ),
          if (provider.isLoadingBins)
            const Expanded(
              child: Center(
                child: LoadingAnimation(
                  icon: Icons.archive,
                  beginColor: Color.fromRGBO(189, 189, 189, 1),
                  endColor: AppColors.primaryBlue,
                  size: 100.0,
                ),
              ),
            )
          else if (provider.bins.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No bins found for: ${_searchController.text}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: provider.toShowBins
                  ? Container(
                      color: Colors.white,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24.0),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.2,
                        ),
                        itemCount: provider.bins.length,
                        itemBuilder: (context, index) => BinCard(
                          binName: provider.bins[index],
                          onTap: () {
                            selectBin(provider.bins[index]); // Set the selected bin first
                            provider.toggle(false);
                          },
                        ),
                      ),
                    )
                  : BinProductsPage(binName: selectedBin ?? ''),
            ),
        ],
      ),
    );
  }
}

class BinCard extends StatelessWidget {
  final String binName;
  final VoidCallback onTap;

  const BinCard({
    required this.binName,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade100,
                Colors.grey.shade50,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                binName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      // fontWeight: FontWeight.w700,
                      color: Colors.grey[850],
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Products',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
