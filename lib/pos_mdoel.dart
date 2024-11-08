import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';

class PrinterConnectModel {
  final String uuid;
  final BasePrinterInput input;

  PrinterType get printerType => input.printerType;

  const PrinterConnectModel({
    required this.input,
    required this.uuid,
  });
}

class EstimationItemDetailsTableData {
  String sn;
  TextEditingController code;
  TextEditingController tagNo;
  String item_description;
  String pcs;
  String gwt;
  String nwt;
  String va;
  String mc;
  String stone;
  String hallMark;
  TextEditingController costDiscount;
  String salesAmount;
  String total;

  String wst_unit = "%"; // will be either "%" or "gm";
  List<dynamic> stoneDetailsTableData = [];

  List<FocusNode> tableFocusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  EstimationItemDetailsTableData({
    required this.sn,
    required this.code,
    required this.tagNo,
    required this.item_description,
    required this.pcs,
    required this.gwt,
    required this.nwt,
    required this.va,
    required this.mc,
    required this.stone,
    required this.hallMark,
    required this.costDiscount,
    required this.salesAmount,
    required this.total,
  });
  Map<String, dynamic> toJsonValue() {
    return {
      "sn": sn,
      "code": code,
      "tagNo": tagNo,
      "item_description": item_description,
      "pcs": pcs,
      "gwt": gwt,
      "nwt": nwt,
      "va": va,
      "mc": mc,
      "stone": stone,
      "hallMark": hallMark,
      "costDiscount": costDiscount.text,
      "salesAmount": salesAmount,
      "total": total,
    };
  }
}
