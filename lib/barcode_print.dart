// ignore_for_file: library_private_types_in_public_api, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:invoice_generator/invoice_generator.dart';
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
    if (selectedDevice?.typePrinter == PrinterType.network) {
      widget.printer = PrinterConnectModel(
        input: TcpPrinterInput(
          ipAddress: selectedDevice?.address ?? '',
          port: selectedDevice?.port ?? 9100,
          paperSize: PaperSize.fromWidth(
            widget.printer?.input.paperSize.value ?? 558,
          ),
        ),
        uuid: '',
      );
    } else if (selectedDevice?.typePrinter == PrinterType.usb) {
      widget.printer = PrinterConnectModel(
        input: UsbPrinterInput(
            name: selectedDevice?.deviceName,
            vendorId: selectedDevice?.vendorId,
            productId: selectedDevice?.productId,
            paperSize: PaperSize.fromWidth(
                widget.printer?.input.paperSize.value ?? 558)),
        uuid: '',
      );
    } else {
      widget.printer = PrinterConnectModel(
        input: BluetoothPrinterInput(
          name: selectedDevice?.deviceName ?? '',
          address: selectedDevice?.address ?? '',
          paperSize:
              PaperSize.fromWidth(widget.printer?.input.paperSize.value ?? 558),
        ),
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
    );

    Uint8List pdf =
        await PrintGenerator.instance.generateEBarcodeSecond(barcodeModel);

    return pdf;
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
                            onTap: () => connectToDevice(devices[index]),
                          );
                        },
                      ),
                    ),
              if (isConnected)
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
