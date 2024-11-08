// ignore_for_file: library_private_types_in_public_api, must_be_immutable

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:invoice_generator/models/barcode_model.dart';
import 'dart:typed_data';

import 'package:pheripheral_test/estimate.dart';
import 'package:pheripheral_test/pos_mdoel.dart';
import 'package:pheripheral_test/pos_thermal_printer.dart';

class UsbPrinterDialog extends StatefulWidget with PosThermalPrinterUtils {
  UsbPrinterDialog({super.key});

  @override
  _UsbPrinterDialogState createState() => _UsbPrinterDialogState();
}

class _UsbPrinterDialogState extends State<UsbPrinterDialog> {
  List<BluetoothPrinter> devices = [];
  bool isConnected = false;
  final printerManager = PrinterManager.instance;
  BluetoothPrinter? selectedDevice;

  @override
  void initState() {
    super.initState();
    scanUsbDevices();
  }

  void scanUsbDevices() {
    printerManager.discovery(type: PrinterType.usb).listen((device) {
      devices.add(BluetoothPrinter(
        deviceName: device.name,
        address: device.address,
        isBle: false,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: PrinterType.usb,
      ));
      setState(() {});
    });
  }

  Future<void> connectToDevice(BluetoothPrinter device) async {
    selectedDevice = device;
    selectPrinter(device);
    setState(() {
      isConnected = true;
    });
  }

  void selectPrinter(BluetoothPrinter device) async {
    if (selectedDevice != null) {
      if ((device.address != selectedDevice!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedDevice!.vendorId != device.vendorId)) {
        await widget.printerManager
            .disconnect(type: selectedDevice!.typePrinter);
      }
    }
    selectedDevice = device;
    if (selectedDevice?.typePrinter == PrinterType.usb) {
      widget.printer = PrinterConnectModel(
        input: UsbPrinterInput(
            name: selectedDevice?.deviceName,
            vendorId: selectedDevice?.vendorId,
            productId: selectedDevice?.productId,
            paperSize: PaperSize.fromWidth(
                widget.printer?.input.paperSize.value ?? 558)),
        uuid: '',
      );
    }
    setState(() {});
  }

  Future<void> printBarcode() async {
    if (isConnected && selectedDevice != null) {
      Uint8List pdfData = await getBarCodePrint(detail: null);

      printerManager.send(type: PrinterType.usb, bytes: pdfData);
    }
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
      width: 75, // Width in millimeters
      height: 12, // Height in millimeters
    );

    // Construct the command string with all details
    String command = """
    SIZE ${barcodeModel.width},${barcodeModel.height}
    CLS
    BARCODE 20,10,"128",50,1,0,2,2,"${barcodeModel.barCode}"
    TEXT 20,70,"0",0,1,1,"Item: ${barcodeModel.itemName}"
    TEXT 20,90,"0",0,1,1,"Code: ${barcodeModel.itemCode}"
    TEXT 20,110,"0",0,1,1,"Purity: ${barcodeModel.goldPurity}"
    TEXT 20,130,"0",0,1,1,"Weight: ${barcodeModel.weight}"
    TEXT 20,150,"0",0,1,1,"Price: ${barcodeModel.price}"
    PRINT 1
  """;

    // Encode the command string to bytes
    List<int> commandBytes = utf8.encode(command);

    // Convert to Uint8List
    Uint8List escPosData = Uint8List.fromList(commandBytes);

    // Send the command to the printer using your printer manager
    return escPosData;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        height: 300,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tag Print'),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              ),
              devices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.0),
                      child: Text("No USB devices found"),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              devices[index].deviceName ?? 'Unknown Device',
                            ),
                            subtitle: Text(devices[index].vendorId.toString()),
                            leading: selectedDevice != null &&
                                    ((devices[index].typePrinter ==
                                                    PrinterType.usb &&
                                                Platform.isWindows
                                            ? devices[index].deviceName ==
                                                selectedDevice!.deviceName
                                            : devices[index].vendorId != null &&
                                                selectedDevice!.vendorId ==
                                                    devices[index].vendorId) ||
                                        (devices[index].address != null &&
                                            selectedDevice!.address ==
                                                devices[index].address))
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () => connectToDevice(devices[index]),
                          );
                        },
                      ),
                    ),
              //if (isConnected)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: printBarcode,
                  child: const Text("Print Tag"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
