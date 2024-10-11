import 'package:flutter/material.dart';
import 'package:inventory_management/provider/invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  @override
  void initState() {
    super.initState();
    // Fetch invoices when the page loads
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    invoiceProvider.fetchInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Page'),
      ),
      body: invoiceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoiceProvider.error != null
          ? Center(child: Text(invoiceProvider.error!))
          : ListView.builder(
        itemCount: invoiceProvider.invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoiceProvider.invoices[index];
          return Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Number: ${invoice.invoiceNumber ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final url = invoice.invoiceUrl;
                          if (url != null && await canLaunch(url)) {
                            await launch(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not launch $url')),
                            );
                          }
                        },
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

