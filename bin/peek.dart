// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final uri = Uri.https('dummyjson.com', '/products/1');
  final response = await http.get(uri);
  final data = jsonDecode(response.body) as Map<String, dynamic>;

  print('statusCode: ${response.statusCode}');
  print('title: ${data['title']}');
  print('dimensions.runtimeType: ${data['dimensions'].runtimeType}');
}
