// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management/provider/show-details-order-provider.dart';
import 'package:provider/provider.dart';

class ShowDetailsOfOrderItem extends StatefulWidget {
  List<String>title;
  List<int>numberOfItme;
   ShowDetailsOfOrderItem({super.key,required this.numberOfItme,required this.title});

  @override
  State<ShowDetailsOfOrderItem> createState() => _ShowDetailsOfOrderItemState();
}

class _ShowDetailsOfOrderItemState extends State<ShowDetailsOfOrderItem> {
  bool val = false;
  // int count=0
  OrderItemProvider? orderItemProvider1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   orderItemProvider1=Provider.of<OrderItemProvider>(context,listen:false);
    
   orderItemProvider1!.numberOfOrderCheckBox(widget.title.length,widget.numberOfItme);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:Consumer<OrderItemProvider>(
        builder:(context,pro,child)=>ListView.builder(itemBuilder:(context,i)=>SizedBox(
          width:MediaQuery.of(context).size.width*0.9,
          // height:MediaQuery.of(context).size.width*(widget.numberOfItme[i]/25),
          child: ListView.builder(
            shrinkWrap:true,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 5),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1),
                  ),
                  elevation: 5,
                  child: Row(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.title[i],
                          style: GoogleFonts.daiBannaSil(
                            fontSize:20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      )),
                      Checkbox(
                          value:orderItemProvider1!.orderItemCheckBox![i][index],
                          onChanged: (val) {
                           orderItemProvider1!.updateCheckBoxValue(i,index);
                          }
                          )
                    ],
                  ),
                ),
              );
            },
            itemCount:widget.numberOfItme[i],
          ),
        ),
        itemCount:widget.title.length,
        ),
      )
      // ),
    );
  }
}
