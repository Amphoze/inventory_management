import 'package:flutter/material.dart';
import 'package:inventory_management/Api/bin_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/bin_products.dart';
import 'package:provider/provider.dart';

class BinMasterPage extends StatefulWidget {
  const BinMasterPage({super.key});

  @override
  State<BinMasterPage> createState() => _BinMasterPageState();
}

class _BinMasterPageState extends State<BinMasterPage> {
  String? selectedBin;

  void selectBin(String? binName) {
    setState(() {
      selectedBin = binName;
    });
  }

  @override
  void initState() {
    super.initState();
    Provider.of<BinApi>(context, listen: false).fetchBins(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BinApi>(
      builder: (context, b, child) => Column(
        children: [
          // if (selectedBin != null)
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.grey.withValues(alpha: 0.1),
          //         spreadRadius: 1,
          //         blurRadius: 4,
          //       ),
          //     ],
          //   ),
          //   padding: const EdgeInsets.all(24.0),
          //   child: Row(
          //     children: [
          //       IconButton(
          //         icon: const Icon(Icons.arrow_back,
          //             color: AppColors.primaryBlue),
          //         onPressed: () => selectBin(null),
          //         tooltip: 'Back to bins list',
          //       ),
          //       const SizedBox(width: 16),
          //       Text(
          //         selectedBin!,
          //         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          //               fontWeight: FontWeight.bold,
          //               color: AppColors.primaryBlue,
          //             ),
          //       ),
          //     ],
          //   ),
          // ),
          b.isLoadingBins
              ? const Expanded(
                  child: Center(
                    child: LoadingAnimation(
                      icon: Icons.archive,
                      beginColor: Color.fromRGBO(189, 189, 189, 1),
                      endColor: AppColors.primaryBlue,
                      size: 100.0,
                    ),
                  ),
                )
              : Expanded(
                  child: b.toShowBins
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(24.0),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio:
                                  MediaQuery.of(context).size.width > 600
                                      ? 1.5
                                      : 1.2,
                            ),
                            itemCount: b.bins.length,
                            itemBuilder: (context, index) => BinCard(
                              title: b.bins[index],
                              onTap: () {
                                selectBin(b
                                    .bins[index]); // Set the selected bin first
                                b.toggle(false);
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
  final String title;
  final VoidCallback onTap;

  const BinCard({
    required this.title,
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[850],
                      letterSpacing: -0.5,
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
