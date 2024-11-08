import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// ignore: depend_on_referenced_packages

class BarcodePrintPreviewWidget extends StatelessWidget {
  final Uint8List pdf;
  const BarcodePrintPreviewWidget({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Preview'),
      ),
      body: PdfPreview(
        build: (format) => Future.value(pdf as FutureOr<Uint8List>),
        pageFormats: const <String, PdfPageFormat>{
          'Roll80': PdfPageFormat.roll80,
        },
      ),
    );
  }
}
