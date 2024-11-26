import 'dart:developer';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management/Api/label-api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:pagination_flutter/pagination.dart';
import 'package:provider/provider.dart';

import 'Api/lable-page-api.dart';

class LabelPage extends StatefulWidget {
  const LabelPage({super.key});

  @override
  State<LabelPage> createState() => _LabelPageState();
}

class _LabelPageState extends State<LabelPage> {
  LabelPageApi? labelPageProvider;
  //final ScrollController controller = ScrollController();
  final GlobalKey<DropdownSearchState<String>> _dropdownKey =
      GlobalKey<DropdownSearchState<String>>();

  bool showLabelForm = false;
  void _toggleFormVisibility() {
    setState(() {
      // Toggle the flag value to show or hide the form
      showLabelForm = !showLabelForm;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false)
          .fetchInventory(page: 1); // Start at page 1
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    });

    getData();
    getDataProduct();
  }

  TextEditingController searchController = TextEditingController();

  // TextEditingController searchController = TextEditingController();

  void getData() async {
    LabelApi po = Provider.of<LabelApi>(context, listen: false);
    labelPageProvider = Provider.of<LabelPageApi>(context, listen: false);
    await labelPageProvider!.getProductDetails();
    await po.getLabel();
  }

  void getDataProduct() async {
    await labelPageProvider!.getProductDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LabelApi>(
      builder: (context, l, child) => Scaffold(
        body: l.labelInformation.isNotEmpty && l.loading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                    Center(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox(
                                width: 300,
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    prefixIcon: const Icon(Icons.search,
                                        color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide:
                                          BorderSide.none, // No border line
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
                                        color: Colors.grey.withOpacity(
                                            0.5), // Border color when enabled
                                        width: 1.0,
                                      ),
                                    ),
                                    hintStyle:
                                        TextStyle(color: Colors.grey[600]),
                                  ),
                                  onChanged: (value) async {
                                    l.searchByLabel(value);
                                  },
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            child: const Icon(Icons.restart_alt),
                            onTap: () {
                              l.cancel();
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.primaryBlue, // Button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              _toggleFormVisibility(); // Toggle form visibility
                            },
                            child: Text(
                              showLabelForm ? 'Back' : 'Create Label',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showLabelForm)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2, left: 16),
                                child: Text("Create Label",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                child: SizedBox(
                                  width: 620,
                                  child: SingleChildScrollView(
                                      child: LabelFormFields(
                                          labelPageProvider:
                                              labelPageProvider)),
                                ),
                              ),
                              const SizedBox(height: 7),
                              LabelButtons(
                                labelPageProvider: labelPageProvider,
                                dropdownKey: _dropdownKey,
                              ),
                              const SizedBox(
                                height: 62,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!showLabelForm) ...[
                      if (searchController.text.isEmpty &&
                          l.labelInformation.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "hit reload",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: 1,
                              child: Card(
                                margin: const EdgeInsets.all(8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white,
                                        // Colors.lightBlueAccent.withOpacity(0.1)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            width: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              child: Image.network(
                                                l
                                                        .labelInformation[index]
                                                            ["images"]
                                                        .isNotEmpty
                                                    ? l.labelInformation[index]
                                                        ["images"][0]
                                                    : "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKIAAACUCAMAAAAnDwKZAAAAaVBMVEX///9NTU1JSUnJycne3t7q6uouLS5jY2NCQkJgYGDw8PD7+/vh4eFGRkZzc3MnJyd9fX2EhIQ1NTU7OzukpKTQ0NCUlJRra2vAwMDX19eurq6amppWVla6uroaGhq0tLSMjIwAAAALCwuxY5kvAAAFIElEQVR4nO2b6ZKrKhSFUUJEcEDBAcXo6fd/yItmjsPpToGdU5fvR6raIFmuzd4g2gA4HA6Hw+FwOBwOh8PhcDgcvwCtoU0KExJTzyJx8vESfWMSfSsYlRjYwZzEmCFig8g3KJEa6GgO+XyJyEk0gAu0CZyLJvgHJLpAm2APF2kEuwK93fUOLkaZl3Ou2nc9ti8xivG05MOMvNe19UCTKr4snXn5XtfWXaz5bXnP3xuPtiXSAd8k5v1bXdsONE3im0TcvtW1dRfZXSJv3uraerqI+1jM5aqKrWS3ni7SvyqMw1UhItvo2n5d7C82+v6qiQXeGgM7TIACc/0jPF7fl1Gxr6LVb/dYRkRtqKpmvSi2fHPX5gMWY3DKeb5akX5/MUaDc1ny1wbC70u8Tj9xsDIUfj3Q8FY3MVtu8dsuosC/l/Z6sclvu5jdJx/NYamJTRe/oRgeHxXiRSUWJRbLpjz9eug/SvS4WGhkL9ARxuovtwKPi8mLjwuVx5qLkTYID9uxrvmLQs+v5ldly8UojjenjBE0U6jPmFceSy6iy5TBl+vI+ZQsnkv0criPRHS77Vud1u6rtJdQq9cksxJoEtzSYHVa0+m0pHCsPC8D2IaLhD38Oq5WzkhWJM4qjwWJJHmKIB8WTxBrCvVwfB4c5iXS7GWMxUu3z1L5y/rG4Rg8VR7jY5GWM3viWZICEC5l821wDFYllvM89fEsZUS+ofBlzWM60GKpksTJy5whNwVq1MNFGZa4qHA2Z5BgK8yvF2U20JSt5Onx6T65Xb6Qp4u6Vx6zLtJsrZT4DylTrNebO/ltkjHs4rrE+0z49zBPJ9y2V/Zy0YvVdV5rv2OirjzXTd3dJOobvLPG4rja5JnjpfLsFWjvugP6ei+wxbny7OeiztJON5xPPqtcZtQdXZzuTOD2tPJyTVPl2dNFvT6Q3vfDPGo87C3RO78Y9H2myrNroH/OWHn2dfHncPjpLo4PQv4BiR8faOMushyb5WjaRYAiwxyIWRcjZANpTqLnhXb4/BdVfZMSrWFG4p+jRdLQhER5sMn6Q0yHw/F/RQQEIO9h001tPNBYxuuouuyrdN74ScKF3dP3KfMSoJMuYPSyMyLGN0ro5e/zwcs3160T+vBsYNzBaSU9wfPh5jS2IuNeKH3nMfciLY4PKI2AZNV5NyYrSNZULQwYArAKBgq6ijUCRCxoJtVNUDVk0DcniTwkYRYBVtAjpEIfBg0WgZgk9lWy+vbMDykrFqAUHXDZecN44NihrxLmYaFKknSQ15ILmGcUD3LaoS+UFCkZQiAUycrIa8Gpp6mUYdGcSJ/2NW4ohzCvG+/9V0hfJB7yJkddDsbf1AfyDqUFiDvAGEDdgLsmpoBlUdr2YTCeIZskJ0V8SFpAOuGXINUSoT7MjqQ/ARAMJIelapovE/96NUoMQBnnqOf0LjGXVEvMGArbQnW9lphoiaKGYxZAXHecAMViRJNEVpPEo4R+U+eTxGogvBjCrq5NuRgCitMo4i30psGYahcl5aOL8lR0vEd46LkOdCnDcQNK8KhNEehPFUCx0ANkDPRJCk+KLx1oUXOtGBZ53SlDEptBl4ogAkWlyikHK4iqA00gaFvaKpE1OpMEY1QmYTm6rNNGMAlIpS3tVSZaWkEaHBCr9OE6E6qlJCmACIPa5NvY9/pyrjdPdaaoOqJa8FB07p9Ty0vzh1Me+9sDWoaKffrKD6EdHXE4HA6Hw+FwOBwOh8PhcHw6/wFnwnFzLAiC/AAAAABJRU5ErkJggg==",
                                                width: 200,
                                                height:
                                                    150, // Fixed height for consistent sizing
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 16.0), // Increased spacing
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                fieldTitle(
                                                    "Name",
                                                    l.labelInformation[index]
                                                            ["name"] ??
                                                        'null'),
                                                fieldTitle(
                                                    "Label SKU",
                                                    l.labelInformation[index]
                                                            ["labelSku"] ??
                                                        'null'),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Product Details ",
                                                      style: GoogleFonts
                                                          .daiBannaSil(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                    const Text(": ",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Products SKU : ",
                                                          style: GoogleFonts
                                                              .daiBannaSil(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                        for (int i = 0;
                                                            i <
                                                                l
                                                                    .labelInformation[
                                                                        index][
                                                                        "products"]
                                                                    .length;
                                                            i++)
                                                          Text(
                                                            "${l.labelInformation[index]["products"][i]["productSku"]}${i == l.labelInformation[index]["products"].length - 1 ? '' : ', '}",
                                                            style: GoogleFonts
                                                                .daiBannaSil(
                                                              fontSize: 20,
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                fieldTitle(
                                                    "quantity",
                                                    l.labelInformation[index]
                                                            ["quantity"]
                                                        .toString()),
                                                // fieldTitle(
                                                //     "Description ",
                                                //     l.labelInformation[index]
                                                //             ["description"] ??
                                                //         'null'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          itemCount: l.labelInformation.length,
                        ),
                      ),
                      // const Spacer(),
                      Row(children: [
                        InkWell(
                          child: const FaIcon(FontAwesomeIcons.chevronLeft),
                          onTap: () async {
                            l.updateCurrentPage(l.totalPage);
                            await l.getLabel();
                          },
                        ),
                        Pagination(
                          numOfPages: l.totalPage,
                          selectedPage: l.currentPage,
                          pagesVisible: 5,
                          spacing: 10,
                          onPageChanged: (page) async {
                            l.updateCurrentPage(page);
                            await l.getLabel();
                          },
                          nextIcon: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          previousIcon: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          activeTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          activeBtnStyle: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppColors.primaryBlue),
                            shape: WidgetStateProperty.all(const CircleBorder(
                              side: BorderSide(
                                  color: AppColors.primaryBlue, width: 1),
                            )),
                          ),
                          inactiveBtnStyle: ButtonStyle(
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor:
                                WidgetStateProperty.all(Colors.white),
                            shape: WidgetStateProperty.all(const CircleBorder(
                              side: BorderSide(
                                  color: AppColors.primaryBlue, width: 1),
                            )),
                          ),
                          inactiveTextStyle: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          child: const FaIcon(FontAwesomeIcons.chevronRight),
                          onTap: () async {
                            l.updateCurrentPage(l.totalPage);
                            await l.getLabel();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 30,
                            width: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.lightBlue),
                            ),
                            child: Center(
                              child: Text('${l.currentPage}/${l.totalPage}'),
                            ),
                          ),
                        ),
                      ])
                    ],
                  ])
            : const Center(child: LoadingLabelAnimation()),
      ),
    );
  }

  Widget fieldTitle(String filTitle, String value,
      {bool show = true,
      double width = 133,
      var fontWeight = FontWeight.bold}) {
    return Container(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            child: Align(
                alignment: Alignment.topLeft,
                child: Text(filTitle,
                    style: GoogleFonts.daiBannaSil(
                        fontSize: 20, fontWeight: fontWeight))),
          ),
          const Text(":",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'googlefont')),
          show
              ? Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.daiBannaSil(
                        fontSize: 20, fontWeight: FontWeight.normal),
                  ),
                )
              : const Text('  '),
        ],
      ),
    );
  }
}

class LoadingLabelAnimation extends StatefulWidget {
  const LoadingLabelAnimation({super.key});

  @override
  _LoadingLabelAnimationState createState() => _LoadingLabelAnimationState();
}

class _LoadingLabelAnimationState extends State<LoadingLabelAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: Colors
          .blue, // You can use AppColors.primaryGreen or any color you prefer
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.label_important,
            color: _colorAnimation.value,
            size: 80,
          ),
        );
      },
    );
  }
}

class LabelFormFields extends StatefulWidget {
  final LabelPageApi? labelPageProvider;

  const LabelFormFields({super.key, this.labelPageProvider});

  @override
  State<LabelFormFields> createState() => _LabelFormFieldsState();
}

class _LabelFormFieldsState extends State<LabelFormFields> {
  @override
  Widget build(BuildContext context) {
    final comboProvider = context.watch<ComboProvider>();
    final TextEditingController searchController = TextEditingController();

    return Column(
      children: [
        _buildCardTextField(widget.labelPageProvider!.nameController, "Name"),
        _buildCardTextField(
            widget.labelPageProvider!.labelSkuController, "Label SKU"),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 600,
            child: DropdownSearch<String>.multiSelection(
              items: comboProvider.products
                  .where((product) =>
                      product.displayName
                          ?.toLowerCase()
                          .contains(searchController.text.toLowerCase()) ??
                      false)
                  .map((product) => product.displayName ?? 'Unknown')
                  .toList(),
              onChanged: (List<String> selectedValues) {
                // Update the selected products in the LabelPageApi
                widget.labelPageProvider
                    ?.updateSelectedProducts(selectedValues);
                print(selectedValues);
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Search and Select Products',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: const PopupPropsMultiSelection.dialog(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Search Products',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildCardTextField(
            widget.labelPageProvider!.imageController, "Image URL"),
        _buildCardTextField(
            widget.labelPageProvider!.descriptionController, "Description"),
        _buildCardTextField(
            widget.labelPageProvider!.quantityController, "Quantity",
            keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildCardTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: SizedBox(
          width: 600, // Set the desired width here
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16.0),
            ),
          ),
        ),
      ),
    );
  }
}

class LabelButtons extends StatelessWidget {
  final LabelPageApi? labelPageProvider;
  final GlobalKey<DropdownSearchState<String>> dropdownKey;

  const LabelButtons(
      {super.key, this.labelPageProvider, required this.dropdownKey});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(
          width: 16,
        ),
        _buildRoundedButton("Reset", Colors.grey, () {
          labelPageProvider!.clearControllers(dropdownKey);
        }),
        const SizedBox(
          width: 16,
        ),
        _buildRoundedButton("Save", Colors.blueAccent, _saveLabel,
            loader: true),
      ],
    );
  }

  Widget _buildRoundedButton(String text, Color color, VoidCallback onPressed,
      {bool loader = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: !(labelPageProvider!.buttonTap) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: (!(labelPageProvider!.buttonTap) || !loader)
            ? Text(text, style: const TextStyle(fontSize: 16))
            : const CircularProgressIndicator(),
      ),
    );
  }

  void _saveLabel() async {
    try {
      labelPageProvider!.buttonTapStatus();
      var res = await labelPageProvider!.createLabel();
      log("res: $res");
      if (res["res"] == "success") {
        print("Label created successfully");
        labelPageProvider!.clearControllers(dropdownKey);
      } else {
        throw res["res"];
      }
    } catch (e) {
      labelPageProvider!.buttonTapStatus();
      print("Error: $e");
    }
  }
}

// Widget _buildDropdownField(String label, List<String> items,
//     String? selectedValue, ValueChanged<String?> onChanged) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8.0),
//     child: DropdownButtonFormField<String>(
//       hint: Text(label),
//       isExpanded: true,
//       value: selectedValue,
//       items: items.map((String value) {
//         return DropdownMenuItem<String>(
//           value: value,
//           child: Text(value),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       decoration: const InputDecoration(
//         border: OutlineInputBorder(),
//       ),
//     ),
//   );
// }

/*
 "labels": [
      {
        "_id": "66e410d5e6ef61bf9fb396bc",
        "name": "label",
        "labelSku": "LB-100",
        "images": [
          "https://yash-private31.s3.eu-north-1.amazonaws.com/label/66e410d5e6ef61bf9fb396bc/1f1054b1-e9c0-4686-9eb9-51dbd169aa67-images.png.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAX5ILZSMN5LZ73PNF%2F20240916%2Feu-north-1%2Fs3%2Faws4_request&X-Amz-Date=20240916T150904Z&X-Amz-Expires=900&X-Amz-Signature=01e4b41ae2b48ddf901133b31a1039337e7902c28f2f1882dd2afb48eac3579d&X-Amz-SignedHeaders=host&x-id=GetObject"
        ],
        "description": "this is a description",
        "product_id": {
          "dimensions": {},
          "_id": "66e3eae439f6c97a6e31fe70",
          "displayName": "Product name",
          "parentSku": "K-tech",
          "sku": "k-tech",
          "ean": "1234567890123",
          "description": "This is a test product description.",
          "brand": "66c0a09dba2bb6d30be80f10",
          "category": "66c0a1a8cbe12342b3849e93",
          "technicalName": "some name",

        },
        "quantity": 9,
        "createdAt": "2024-09-13T10:15:49.471Z",
        "updatedAt": "2024-09-16T05:49:13.434Z",
        "__v": 1
      },
*/