import 'package:flutter/material.dart';
import 'package:inventory_management/provider/invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    invoiceProvider.fetchInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by invoice no.',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              final invoiceNumber = _searchController.text;
                              if (invoiceNumber.isNotEmpty) {
                                invoiceProvider
                                    .searchInvoiceByNumber(invoiceNumber);
                              } else {
                                invoiceProvider.fetchInvoices();
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none, // No border line
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(
                              color: AppColors
                                  .primaryBlue, // Border color when focused
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 
                                  0.5), // Border color when enabled
                              width: 1.0,
                            ),
                          ),
                        ),
                        onSubmitted: (value) async {
                          invoiceProvider.searchInvoiceByNumber(value);
                        },
                        onChanged: (value) async {
                          if (value.isEmpty) {
                            invoiceProvider.fetchInvoices();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: invoiceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : invoiceProvider.error != null
                    ? Center(child: Text(invoiceProvider.error!))
                    : ListView.builder(
                        itemCount: invoiceProvider.invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoiceProvider.invoices[index];

                          // Format the createdAt date and time
                          // String formattedDate = DateFormat('yyyy-MM-dd')
                          //     .format(invoice.createdAt);
                          // String formattedTime =
                          //     DateFormat('hh:mm a').format(invoice.createdAt);

                          // Convert to IST (UTC+5:30)
                          DateTime istDateTime = invoice.createdAt
                              .add(const Duration(hours: 5, minutes: 30));

                          // Format the IST date and time
                          String formattedDate =
                              DateFormat('yyyy-MM-dd').format(istDateTime);
                          String formattedTime =
                              DateFormat('hh:mm a').format(istDateTime);

                          return Card(
                            margin: const EdgeInsets.all(16.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Invoice Number: ${invoice.invoiceNumber ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final url = invoice.invoiceUrl;
                                          if (url != null &&
                                              await canLaunch(url)) {
                                            await launch(url);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Could not launch $url'),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('View'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Created On: $formattedDate at $formattedTime',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Pagination controls
          CustomPaginationFooter(
            currentPage: invoiceProvider.currentPage,
            totalPages: invoiceProvider.totalPages,
            buttonSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
            onFirstPage: () => invoiceProvider.goToFirstPage(),
            onLastPage: () => invoiceProvider.goToLastPage(),
            onNextPage: () => invoiceProvider.nextPage(),
            onPreviousPage: () => invoiceProvider.previousPage(),
            onGoToPage: (int) => invoiceProvider.goToPage(int),
            onJumpToPage: () {},
            pageController: _pageController,
          ),
        ],
      ),
    );
  }
}
