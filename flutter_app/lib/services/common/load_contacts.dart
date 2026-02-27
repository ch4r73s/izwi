import 'dart:io';

import 'package:excel/excel.dart';

Future<void> loadContacts(String path) async {
  var file = File(path);
  var bytes = file.readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  // for (var table in excel.tables.keys) {
  //   print(table); //sheet Name
  //   print(excel.tables[table]?.maxCols);
  //   print(excel.tables[table]?.maxRows);
  //   for (var row in excel.tables[table]!.rows) {
  //     print('$row');
  //     // Process row data (e.g., row[0] for names, row[1] for phone numbers)
  //   }
  // }
  for (var table in excel.tables.keys) {
    var sheet = excel.tables[table];
    for (var row in sheet!.rows) {
      String name = row[0]?.toString() ?? '';
      String phoneNumber = row[1]?.toString() ?? '';
      String emailAddress = row[2]?.toString() ?? '';
      
      print('Name: $name, Phone Number: $phoneNumber, Email: $emailAddress');
      // Use this data in your app
    }
  }
}
