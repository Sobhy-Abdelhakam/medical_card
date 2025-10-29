// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../model/dataModel.dart';

// class DataService {
//   final String apiUrl = "https://sheets.googleapis.com/v4/spreadsheets/YOUR_SHEET_ID/values/Sheet1?key=YOUR_API_KEY";

//   Future<List<ServiceProvider>> fetchData(String item) async {
//     try {
//       final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);

//         if (jsonData is Map && jsonData.containsKey("values")) {
//           final List<dynamic> values = jsonData["values"];
//           if (values.isNotEmpty) {
//             final List rows = values.skip(3).toList();
//             return rows
//                 .where((row) => row.length > 1)
//                 .map((row) => ServiceProvider.fromRawList(row))
//                 .where((provider) => provider.type.contains(item))
//                 .toList();
//           }
//         }
//       }
//       throw Exception('خطأ في تحميل البيانات');
//     } catch (e) {
//       throw Exception("فشل تحميل البيانات، تأكد من اتصال الإنترنت.");
//     }
//   }
// }
