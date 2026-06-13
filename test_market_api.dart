import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final uri = Uri.https(
    'api.data.gov.in',
    '/resource/9ef84268-d588-465a-a308-a864a43d0070',
    {
      'api-key': '579b464db66ec23bdd000001e9e7737133ee46f6465bd64fad3da183',
      'format': 'json',
      'limit': '5',
      'filters[commodity]': 'Tomato',
    },
  );
  print('URL: $uri');
  final r = await http.get(uri);
  print('STATUS: ${r.statusCode}');
  if (r.statusCode == 200) {
    final data = json.decode(r.body);
    print('Total: ${data['total']}');
    print('Count: ${data['count']}');
    final records = data['records'] as List?;
    if (records != null && records.isNotEmpty) {
      for (var rec in records) {
        print('---');
        print('State: ${rec['state']}');
        print('District: ${rec['district']}');
        print('Market: ${rec['market']}');
        print('Commodity: ${rec['commodity']}');
        print('Min: ${rec['min_price']}');
        print('Max: ${rec['max_price']}');
        print('Modal: ${rec['modal_price']}');
        print('Date: ${rec['arrival_date']}');
      }
    } else {
      print('No records found.');
      print('Keys: ${data.keys}');
    }
  } else {
    print('Error body: ${r.body}');
  }
}
