// // ignore_for_file: library_private_types_in_public_api, prefer_final_fields

// import 'dart:html' as html;
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:inventory_management/Api/products-provider.dart';
// import 'package:provider/provider.dart';

// class MultiImagePicker{


// /// Picks multiple images and returns their URLs (for web) or file paths (for mobile).
// Future<List<String>> pickImages(BuildContext context) async {
//   final ImagePicker picker = ImagePicker();
//   List<String> imageUrls = [];

//   if (kIsWeb) {
//     final fileInput = html.FileUploadInputElement()
//       ..accept = 'image/*'
//       ..multiple = true;
//     fileInput.click();

   
//     final completer = Completer<List<String>>();
//     fileInput.onChange.listen((e) async {
//       final files = fileInput.files;
      
//       if (files != null) {
//         await Provider.of<ProductProvider>(context,listen:false).setImage(files,);
//         List<String> base64Images = [];
//         for (var file in files) {
//           final reader = html.FileReader();
//           reader.readAsDataUrl(file);
//           reader.onLoadEnd.listen((e) {
//             base64Images.add(reader.result as String);
//             if (base64Images.length == files.length) {
//               completer.complete(base64Images);
//             }
//           });
//         }
//       } else {
//         completer.complete([]);
//       }
//     });
//     return completer.future;
//   } else {
//     final pickedFiles = await picker.pickMultiImage();
//     if (pickedFiles != null) {
//       return pickedFiles.map((file) => file.path).toList();
//     } else {
//       return [];
//     }
//   }
// }

// }



// class CustomHorizontalImageScroller extends StatefulWidget {
//   final List<String>? webImageUrls; 
//   final List<XFile>? mobileImageFiles; 

//   const CustomHorizontalImageScroller({
//     super.key,
//     this.webImageUrls,
//     this.mobileImageFiles,
//   });

//   @override
//   _CustomHorizontalImageScrollerState createState() => _CustomHorizontalImageScrollerState();
// }

// class _CustomHorizontalImageScrollerState extends State<CustomHorizontalImageScroller> {
//   ScrollController _scrollController = ScrollController();

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Debugging information to verify what data is present
  
    
//     return kIsWeb
//         ? (widget.webImageUrls == null || widget.webImageUrls!.isEmpty
//             ? const Center(child: Text('No images selected.'))
//             : Scrollbar(
//                 controller: _scrollController,
//                 trackVisibility: true,
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   controller: _scrollController,
//                   child: Row(
//                     children: widget.webImageUrls!.map((url) {
//                       return _buildImageWithDeleteButton(
//                         url: url,
//                         isWeb: true,
//                         onDelete: () {
//                           // Handle delete action for web images
//                           setState(() {
//                             widget.webImageUrls!.remove(url);
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ))
//         : (widget.mobileImageFiles == null
//             ? const Center(child: Text('No images selected.'))
//             : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: widget.mobileImageFiles!.map((file) {
//                     return _buildImageWithDeleteButton(
//                       url: file.path,
//                       isWeb: false,
//                       onDelete: () {
//                         // Handle delete action for mobile images
//                         setState(() {
//                           widget.mobileImageFiles!.remove(file);
//                         });
//                       },
//                     );
//                   }).toList(),
//                 ),
//               ));
//   }

//   Widget _buildImageWithDeleteButton({
//     required String url,
//     required bool isWeb,
//     required VoidCallback onDelete,
//   }) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: Stack(
//         children: [
//           // The image itself
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5.0),
//             child: SizedBox(
//               height: 200,
//               width: 100,
//               child: isWeb
//                   ? Image.network(url, fit: BoxFit.cover)
//                   : Image.file(File(url), fit: BoxFit.cover),
//             ),
//           ),
//           // Delete button overlay
//           Positioned(
//             right: 0,
//             top: 0,
//             child: GestureDetector(
//               onTap: onDelete,
//               child: Container(
//                 color: Colors.red.withOpacity(0.6),
//                 padding: const EdgeInsets.all(8.0),
//                 child: Icon(
//                   Icons.delete,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
// import 'dart:html';
// import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:provider/provider.dart';

class CustomPicker extends StatefulWidget {
  const CustomPicker({super.key});

  @override
  State<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> {
  List<File> _images=[];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
      // pickedFiles[0].r
    if (pickedFiles.isNotEmpty) {
     
      setState(() {
        _images = pickedFiles.map((e) =>File(e.path)).toList();
      });
      // await fun(pickedFiles[0]);
      // print("succes 2");
      await Provider.of<ProductProvider>(context,listen:false).setImage(_images);
    } else {
      print('No images selected.');
    }
  }

  // Future fun(XFile file)async{
  //   await file.readAsBytes();
  //   print("success");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Image Picker')),
      body: Center(
        child: _images.isEmpty
            ? Center(
              child: InkWell(
                  onTap:()async{
                    // print("i am c");
                    await pickImages();
                  },
                  child: Container(
                    padding:const EdgeInsets.all(16),
                    color: Colors.blue,
                    child:const Text(
                      'Pick Images',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
            )
            : GridView.builder(
                gridDelegate:const  SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return (kIsWeb)?Image.network(_images[index].path):Image.file(_images[index]);
                },
              ),
      ),
    );
  }
}
