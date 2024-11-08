import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos_printer_platform/esc_pos_utils_platform/src/enums.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:get/get.dart';
import 'package:pheripheral_test/pos_mdoel.dart';
import 'package:pheripheral_test/pos_thermal_printer.dart';

class EstimateDialogPrinter extends StatefulWidget with PosThermalPrinterUtils {
  EstimateDialogPrinter({super.key});

  @override
  _EstimateDialogPrinterState createState() => _EstimateDialogPrinterState();
}

class _EstimateDialogPrinterState extends State<EstimateDialogPrinter> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String ipAddress = '';
  int port = 9100;
  StreamSubscription<PrinterDevice>? subscription;
  bool isPrinterConnecting = false;
  PrinterType? defaultPrinterType;
  List<BluetoothPrinter> devices = [];
  BluetoothPrinter? selectedPrinter;
  bool isBle = false;
  bool isConnected = false;

  final FocusNode ipFocusNode = FocusNode();
  final TextEditingController ipController = TextEditingController();
  final FocusNode portFocusNode = FocusNode();
  final TextEditingController portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial setup
    defaultPrinterType = PrinterType.network; // Default value
    scan(); // Simulate scanning devices
  }

  void scan() {
    setState(() {
      devices.clear();
      subscription = widget.printerManager
          .discovery(type: defaultPrinterType!, isBle: isBle)
          .listen((device) {
        devices.add(BluetoothPrinter(
          deviceName: device.name,
          address: device.address,
          isBle: isBle,
          vendorId: device.vendorId,
          productId: device.productId,
          typePrinter: defaultPrinterType!,
        ));
      });
    });
  }

  void selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedPrinter!.vendorId != device.vendorId)) {
        await widget.printerManager
            .disconnect(type: selectedPrinter!.typePrinter);
      }
    }
    selectedPrinter = device;
    if (selectedPrinter?.typePrinter == PrinterType.network) {
      widget.printer = PrinterConnectModel(
        input: TcpPrinterInput(
          ipAddress: selectedPrinter?.address ?? '',
          port: selectedPrinter?.port ?? 9100,
          paperSize: PaperSize.fromWidth(
            widget.printer?.input.paperSize.value ?? 558,
          ),
        ),
        uuid: '',
      );
    } else if (selectedPrinter?.typePrinter == PrinterType.usb) {
      widget.printer = PrinterConnectModel(
        input: UsbPrinterInput(
            name: selectedPrinter?.deviceName,
            vendorId: selectedPrinter?.vendorId,
            productId: selectedPrinter?.productId,
            paperSize: PaperSize.fromWidth(
                widget.printer?.input.paperSize.value ?? 558)),
        uuid: '',
      );
    } else {
      widget.printer = PrinterConnectModel(
        input: BluetoothPrinterInput(
          name: selectedPrinter?.deviceName ?? '',
          address: selectedPrinter?.address ?? '',
          paperSize:
              PaperSize.fromWidth(widget.printer?.input.paperSize.value ?? 558),
        ),
        uuid: '',
      );
    }
    setState(() {});
  }

  void resetController() {
    setState(() {
      isPrinterConnecting = false;
      selectedPrinter = null;
      ipController.clear();
      portController.clear();
    });
  }

  void setPort(String value) {
    if (value.isEmpty) value = '9100';
    port = int.tryParse(value) ?? 0;
    var device = BluetoothPrinter(
      deviceName: value,
      address: ipAddress,
      port: port,
      typePrinter: PrinterType.network,
      state: false,
    );
    selectDevice(device);
  }

  void setIpAddress(String value) {
    ipAddress = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: ipAddress,
      port: port,
      typePrinter: PrinterType.network,
      state: false,
    );
    selectDevice(device);
  }

  Future<void> printEstimate() async {
    // Simulate printing process
    setState(() {
      isPrinterConnecting = true;
    });
    final result = await widget.printEstimateSlip();

    await Future.delayed(const Duration(seconds: 2));
    if (result) {
      Get.snackbar(
        "Success",
        "Estimate printed successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {}
    setState(() {
      isPrinterConnecting = false;
      resetController();
    });
  }

  @override
  void dispose() {
    ipFocusNode.dispose();
    ipController.dispose();
    portFocusNode.dispose();
    portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        height: MediaQuery.of(context).size.height * 0.35,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Expanded(
                child: isPrinterConnecting
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<PrinterType>(
                                value: defaultPrinterType,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.print,
                                    size: 24,
                                  ),
                                  labelText: "Type Printer Device",
                                  labelStyle: TextStyle(fontSize: 18.0),
                                  border: OutlineInputBorder(),
                                ),
                                items: <DropdownMenuItem<PrinterType>>[
                                  if (Platform.isAndroid || Platform.isIOS)
                                    const DropdownMenuItem(
                                      value: PrinterType.bluetooth,
                                      child: Text("Bluetooth"),
                                    ),
                                  if (Platform.isAndroid || Platform.isWindows)
                                    const DropdownMenuItem(
                                      value: PrinterType.usb,
                                      child: Text("USB"),
                                    ),
                                  const DropdownMenuItem(
                                    value: PrinterType.network,
                                    child: Text("WiFi"),
                                  ),
                                ],
                                onChanged: (PrinterType? value) {
                                  if (value != null) {
                                    setState(() {
                                      defaultPrinterType = value;
                                      selectedPrinter = null;
                                      isBle = false;
                                      isConnected = false;
                                    });
                                    scan();
                                  }
                                },
                              ),
                              Visibility(
                                visible:
                                    defaultPrinterType == PrinterType.bluetooth,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: devices.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(
                                              devices[index].deviceName ?? ''),
                                          onTap: () {
                                            selectDevice(devices[index]);
                                          },
                                          selected: selectedPrinter?.address ==
                                              devices[index].address,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (defaultPrinterType ==
                                  PrinterType.network) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  focusNode: ipFocusNode,
                                  controller: ipController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter IP Address',
                                    hintText: 'E.g., 192.168.1.1',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: setIpAddress,
                                  validator: (val) {
                                    final ipPattern = RegExp(
                                        r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
                                    if (val == null || val.isEmpty) {
                                      return 'IP Address cannot be empty';
                                    } else if (!ipPattern.hasMatch(val)) {
                                      return 'Enter a valid IP Address';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  focusNode: portFocusNode,
                                  controller: portController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Port',
                                    hintText: 'E.g., 9100 (Range: 1–65535)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: setPort,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Port cannot be empty';
                                    } else if (int.tryParse(val) == null ||
                                        int.parse(val) < 1 ||
                                        int.parse(val) > 65535) {
                                      return 'Enter a valid port number (1-65535)';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      resetController();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: isPrinterConnecting
                        ? () {}
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (selectedPrinter != null) {
                                isPrinterConnecting = true;
                                setState(() {});

                                try {
                                  await printEstimate();
                                } finally {
                                  isPrinterConnecting = false;
                                  resetController();
                                  setState(() {});
                                }
                              } else {
                                Get.snackbar(
                                    "Error", "Please select a printer device",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPrinterConnecting
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      isPrinterConnecting ? "Printing..." : "Print",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BluetoothPrinter {
  int? id;
  String? deviceName;
  String? address;
  int? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;

  BluetoothPrinter({
    this.deviceName,
    this.address,
    this.port,
    this.state,
    this.vendorId,
    this.productId,
    this.typePrinter = PrinterType.bluetooth,
    this.isBle = false,
  });
}
