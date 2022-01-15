import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(Uri.parse(url));

    try {
      // daca s-a primit raspuns "200" inseamna ca este ok.
      if (response.statusCode == 200) {
        String jsonData = response.body;
        var decodeData = jsonDecode(jsonData);

        return decodeData;
      }

      // eroare conectare
      return "failed";
    } on Exception catch (e) {
      // TODO
      return "failed";
    }
  }
}
