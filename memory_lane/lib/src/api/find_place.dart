import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class LocationService {
  final String key = 'AIzaSyCne8NhkeffWaLxuydcuIONDrmUOwQpQ8w';

  Future<String> getPlaceId(String input) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = convert.jsonDecode(response.body);
        final placeId = json['candidates'][0]['place_id'] as String;
        return placeId;
      } else {
        throw Exception(
            'placeID를 불러오는데 실패하였습니다. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('place ID 오류: $e');
    }
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    try {
      final placeId = await getPlaceId(input);
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var json = convert.jsonDecode(response.body);
        var results = json['result'] as Map<String, dynamic>;
        return results;
      } else {
        throw Exception(
            '장소 상세정보를 불러오지 못하였습니다. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('place details 오류: $e');
    }
  }
}
