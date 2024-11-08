// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'package:invoice_generator/invoice_generator.dart';
import 'package:invoice_generator/models/barcode_model.dart';

import 'barcode_print.dart';
import 'estimate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  List<Printer> printers = [];
  Uint8List? pdf;
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Printer Slip Demo'),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  printBarCode();
                },
                child: const Text('Tag Printer'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.dialog(
                    EstimateDialogPrinter(),
                  );
                },
                child: const Text('Thermal Printer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  printBarCode() async {
    try {
      pdf = await getBarCodePrint(detail: null);
      if (pdf != null) {
        Get.to(
          () => BarcodePrintPreviewWidget(
            pdf: pdf!,
          ),
        );
      }
    } catch (e) {
      log(e.toString());
    }
  }

  // Get Printer List
  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
    ]);
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
        .listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers
            .removeWhere((element) => element.name == null || element.name == ''
                //  ||
                // !element.name!.toLowerCase().contains('print')
                );
      });
    });
  }

  Future<Uint8List> getBarCodePrint({required dynamic detail}) async {
    final BarcodeModel barcodeModel = BarcodeModel(
      barCode: '590123412345',
      itemName: "Gold Necklace",
      itemCode: "C16-24",
      goldPurity: "22K",
      weight: "15g",
      price: '20,989',
      phone: '',
      showNumber: true,
    );

    Uint8List pdf =
        await PrintGenerator.instance.generateEBarcodeSecond(barcodeModel);

    return pdf;
  }
}
