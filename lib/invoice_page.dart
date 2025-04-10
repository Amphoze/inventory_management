import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inventory_management/provider/invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/utils.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  late InvoiceProvider pro;
  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      pro.fetchInvoices();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      pro.searchInvoiceByNumber(value);
    });
  }

  @override
  void initState() {
    super.initState();

    pro = Provider.of<InvoiceProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_){
      pro.fetchInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                SizedBox(
                  height: 35,
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by invoice no.',
                      // prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: InkWell(
                        child: const Icon(Icons.search),
                        onTap: () {
                          final invoiceNumber = _searchController.text;
                          if (invoiceNumber.isNotEmpty) {
                            invoiceProvider.searchInvoiceByNumber(invoiceNumber);
                          } else {
                            invoiceProvider.fetchInvoices();
                          }
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(8),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue, // Border color when focused
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.5), // Border color when enabled
                          width: 1.0,
                        ),
                      ),
                    ),
                    onSubmitted: (value) async {
                      invoiceProvider.searchInvoiceByNumber(value);
                    },
                    onChanged: _onSearchChanged,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () {
                    invoiceProvider.fetchInvoices();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: invoiceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : invoiceProvider.error != null
                    ? Center(child: Text(invoiceProvider.error!))
                    : invoiceProvider.invoices.isEmpty
                        ? const Center(child: Text('No invoices found'))
                        : ListView.builder(
                            itemCount: invoiceProvider.invoices.length,
                            itemBuilder: (context, index) {
                              final invoice = invoiceProvider.invoices[index];

                              String formattedDate = '';
                              String formattedTime = '';

                              if (invoice.createdAt != null) {
                                DateTime istDateTime = invoice.createdAt!.add(const Duration(hours: 5, minutes: 30));
                                formattedDate = DateFormat('yyyy-MM-dd').format(istDateTime);
                                formattedTime = DateFormat('hh:mm a').format(istDateTime);
                              }

                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Utils.richText('Invoice Number: ', invoice.invoiceNumber ?? 'N/A',
                                              fontSize: 16),
                                          Utils.richText('Order ID: ', invoice.invoiceNumber ?? '', fontSize: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              const Icon(Icons.access_time, size: 14),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                              Text(
                                                '$formattedDate at $formattedTime',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final url = invoice.invoiceUrl;
                                          if (await canLaunchUrl(Uri.parse(url))) {
                                            await launchUrl(Uri.parse(url));
                                          } else {
                                            Utils.showSnackBar(context, 'Could not launch $url', isError: true);
                                          }
                                        },
                                        child: const Text('View'),
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
            totalCount: invoiceProvider.totalInvoices,
            buttonSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
            onFirstPage: () => invoiceProvider.goToFirstPage(),
            onLastPage: () => invoiceProvider.goToLastPage(),
            onNextPage: () => invoiceProvider.nextPage(),
            onPreviousPage: () => invoiceProvider.previousPage(),
            onGoToPage: (value) => invoiceProvider.goToPage(value),
            onJumpToPage: () {},
            pageController: _pageController,
          ),
        ],
      ),
    );
  }
}
