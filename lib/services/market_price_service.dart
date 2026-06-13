import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MarketPriceService {
  static const String _baseUrl = 'https://api.data.gov.in/resource';
  
  // Get market prices for a commodity
  Future<Map<String, dynamic>?> getMarketPrices({
    required String commodity,
    String? state,
    String? district,
    String? market,
    int limit = 50, // Increased limit to get more nearby results
  }) async {
    print('🌾 [MarketPriceService] Starting API call...');
    print('   • Commodity: $commodity');
    print('   • State: $state');
    print('   • District: $district');
    print('   • Market: $market');
    
    try {
      // Use the market price resource ID from data.gov.in
      final resourceId = '9ef84268-d588-465a-a308-a864a43d0070'; // Market prices resource

      final params = {
        'api-key': ApiConfig.ogdApiKey,
        'format': 'json',
        'limit': limit.toString(),
      };

      if (commodity.isNotEmpty) {
        params['filters[commodity]'] = commodity;
      }
      
      // Try with state first for nearby results
      if (state != null && state.isNotEmpty) {
        params['filters[state]'] = state;
      }

      final uri = Uri.https('api.data.gov.in', '/resource/$resourceId', params);
      print('   • API URL: $uri');
      
      print('   • Making HTTP request...');
      final response = await http.get(uri);
      print('   • Response status: ${response.statusCode}');
      print('   • Response length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   • Parsed JSON successfully');
        
        if (data['records'] != null) {
          var records = data['records'] as List;
          print('   • Found ${records.length} records from API');
          
          // If we have district, prioritize those markets with better sorting
          if (district != null && district.isNotEmpty && records.isNotEmpty) {
            final targetDistrict = district.toLowerCase().trim();
            
            // Sort records: exact district matches first, then partial matches, then others
            records.sort((a, b) {
              final aDistrict = (a['district'] ?? '').toString().toLowerCase().trim();
              final bDistrict = (b['district'] ?? '').toString().toLowerCase().trim();
              
              // Check for exact match
              final aExact = aDistrict == targetDistrict;
              final bExact = bDistrict == targetDistrict;
              
              if (aExact && !bExact) return -1;
              if (!aExact && bExact) return 1;
              
              // Check for partial match
              final aPartial = aDistrict.contains(targetDistrict) || targetDistrict.contains(aDistrict);
              final bPartial = bDistrict.contains(targetDistrict) || targetDistrict.contains(bDistrict);
              
              if (aPartial && !bPartial) return -1;
              if (!aPartial && bPartial) return 1;
              
              return 0;
            });
            print('   • Sorted records: exact matches first, then partial, for district: $district');
          }
          
          data['records'] = records;
        } else {
          print('   • No records field in response');
          print('   • Response keys: ${data.keys.toList()}');
        }
        return data;
      } else {
        print('❌ Market Price API error: ${response.statusCode}');
        print('   • Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching market prices: $e');
      print('   • Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Format market price data
  String formatMarketPriceData(Map<String, dynamic> data, String language) {
    try {
      final records = data['records'] as List<dynamic>?;
      if (records == null || records.isEmpty) {
        return language.contains('Hindi') || language.contains('हिन्दी')
            ? 'इस वस्तु के लिए बाजार मूल्य उपलब्ध नहीं है।'
            : 'Market price data not available for this commodity.';
      }

      final buffer = StringBuffer();
      
      if (language.contains('Hindi') || language.contains('हिन्दी')) {
        buffer.writeln('📊 बाजार मूल्य:\n');
        for (var record in records.take(5)) {
          final market = record['market'] ?? 'अज्ञात';
          final minPrice = record['min_price'] ?? 'N/A';
          final maxPrice = record['max_price'] ?? 'N/A';
          final modalPrice = record['modal_price'] ?? 'N/A';
          final arrival = record['arrival_date'] ?? 'N/A';
          
          buffer.writeln('बाजार: $market');
          buffer.writeln('न्यूनतम मूल्य: ₹$minPrice');
          buffer.writeln('अधिकतम मूल्य: ₹$maxPrice');
          buffer.writeln('मॉडल मूल्य: ₹$modalPrice');
          buffer.writeln('तारीख: $arrival');
          buffer.writeln('---');
        }
      } else {
        buffer.writeln('📊 Market Prices:\n');
        for (var record in records.take(5)) {
          final market = record['market'] ?? 'Unknown';
          final minPrice = record['min_price'] ?? 'N/A';
          final maxPrice = record['max_price'] ?? 'N/A';
          final modalPrice = record['modal_price'] ?? 'N/A';
          final arrival = record['arrival_date'] ?? 'N/A';
          
          buffer.writeln('Market: $market');
          buffer.writeln('Min Price: ₹$minPrice');
          buffer.writeln('Max Price: ₹$maxPrice');
          buffer.writeln('Modal Price: ₹$modalPrice');
          buffer.writeln('Date: $arrival');
          buffer.writeln('---');
        }
      }

      return buffer.toString();
    } catch (e) {
      print('Error formatting market price data: $e');
      return 'Error formatting market price data';
    }
  }
}
