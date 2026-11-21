import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';


// NEW FUNCTION:
Future<List<String>?> convertExistingPdfToImages(String pdfPath) async {
  try {
    final document = await PdfDocument.openFile(pdfPath);
    List<String> imagePaths = [];
    final tempDir = await getTemporaryDirectory();

    for (int pageNumber = 1; pageNumber <= document.pagesCount; pageNumber++) {
      final page = await document.getPage(pageNumber);
      
      // Render the page as an image
      final pageImage = await page.render(
        width: page.width * 3, // 3x scale for high resolution OCR
        height: page.height * 3,
        format: PdfPageImageFormat.jpeg,
      );

      if (pageImage != null) {
        // Save the image to temporary storage
        File tempFile = File('${tempDir.path}/pdf_page_$pageNumber.jpg');
        await tempFile.writeAsBytes(pageImage.bytes);
        imagePaths.add(tempFile.path);
      }
      
      await page.close();
    }
    
    return imagePaths;
  } catch (e) {
    print("Error converting existing PDF: $e");
    return null;
  }
}

// ---------------------------------------------------
// Pick PDF and Convert EVERY Page to Images
// ---------------------------------------------------
Future<List<String>?> pickAndConvertPdf() async {
  // 1. Pick the PDF file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null || result.files.single.path == null) {
    return null; // User canceled
  }

  String pdfPath = result.files.single.path!;
  List<String> imagePaths = []; // We will store all the generated image paths here

  try {
    final document = await PdfDocument.openFile(pdfPath);
    final tempDir = await getTemporaryDirectory();

    // 2. Loop through EVERY page in the document
    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);

      // Render the page to an ultra high-res image
      final pageImage = await page.render(
        width: page.width * 3, 
        height: page.height * 3,
        format: PdfPageImageFormat.jpeg,
      );

      await page.close();

      if (pageImage != null) {
        // Save each page as a unique image file (e.g., temp_pdf_page_1.jpg)
        final file = await File('${tempDir.path}/temp_pdf_page_$i.jpg').create();
        await file.writeAsBytes(pageImage.bytes);
        
        imagePaths.add(file.path); // Add it to our list!
      }
    }
    
    await document.close();
    return imagePaths; // Return the full list of pages

  } catch (e) {
    print("Error converting PDF: $e");
    return null;
  }
}