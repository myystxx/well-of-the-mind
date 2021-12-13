import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const AUTH_URL = "https://accounts.spotify.com/api/token";
const SPOTIFY_API = 'https://api.spotify.com/v1';
/* edit this to call the respective web API */
const PLAYLIST_URL = SPOTIFY_API + '/playlists/37i9dQZF1DWZqd5JICZI0u/tracks';

class SpotifyAuth {
  String ACCESS_TOKEN;

  dynamic _getCredentials() {
    String credentials = dotenv.env['CLIENT_ID'].toString() +
        ':' +
        dotenv.env['CLIENT_SECRET'].toString();
    String encodedCredentials = base64.encode(utf8.encode(credentials));
    return encodedCredentials;
  }

  Future<dynamic> _performAuth() async {
    dynamic encodedCredentials = _getCredentials();
    final response = await http.post(
      Uri.parse(AUTH_URL),
// Send authorization headers to the backend.
      headers: {HttpHeaders.authorizationHeader: 'Basic $encodedCredentials'},
      body: {'grant_type': 'client_credentials'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(response.statusCode);
      throw Exception("Could not authenticate client");
    }
  }

  bool verifyTimeout(expires) {
    var now = new DateTime.now();
    var expired = now.add(new Duration(seconds: expires));
    var timeToExpire = expired.difference(now).inSeconds;
    //check if access token expired
    if (timeToExpire < 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> _getAccessToken() async {
    final data = await _performAuth();
    ACCESS_TOKEN = data['access_token'];
    print(ACCESS_TOKEN);
    var expiresIn = data['expires_in'];
    if (verifyTimeout(expiresIn)) {
      _getAccessToken();
    }
    return ACCESS_TOKEN;
  }

  Future<dynamic> fetchShow() async {
    ACCESS_TOKEN = await _getAccessToken();
    print('Bearer $ACCESS_TOKEN');
    print('$PLAYLIST_URL?market=ES&limit=5');
    int startTime = new DateTime.now().microsecond;
    // https://api.spotify.com/v1/shows/{id}/episodes?market=US&limit=1
    final response = await http.get(
      Uri.parse('$PLAYLIST_URL?market=ES&limit=5'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $ACCESS_TOKEN',
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      int endTime = new DateTime.now().microsecond - startTime;
      print("spotify: $endTime");
      return data;
    } else {
      print(jsonDecode(response.body)["error"]["message"]);
      throw Exception("Could not authenticate client");
    }
  }
}

// this is to display show
class Track {
  String title;
  String artist;
  String audio_url;
  String external_url;

  Track(
    this.title,
    this.artist,
    this.audio_url,
    this.external_url,
  );
  // factory Track.fromJson(Map<String, dynamic> json) {
  //   return Track(
  //     audio_url: json['items'][0]['audio_preview_url'],
  //     title: json['items'][0]['name'],
  //     description: json['items'][0]['description'],
  //   );
  // }
}
