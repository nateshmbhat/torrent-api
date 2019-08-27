import 'dart:convert';
import 'dart:developer';

import 'package:meta/meta.dart';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:torrent_api/src/u_torrent_api/session.dart';

/// Instantiate [UTorrentApi] class to get access to a host of methods
class UTorrentApi {
  final String serverIp;
  final int serverPort;
  final String baseUrl;

  final Session _session = Session();

  Map<String, String> actions;

  /// Expects serverIp and serverPort
  /// of the uTorrent server
  UTorrentApi({@required this.serverIp, @required this.serverPort})
      : baseUrl = 'http://$serverIp:$serverPort/gui/' {
    assert(serverIp != null);
    assert(serverPort != null);
  }

  /// Pass-in username and password to log-in the user.
  ///
  /// Returns true on successful autentication, otherwise false.
  Future<bool> logIn({String username, String password}) async {
    String authCredentials = 'Basic ' +
        base64.encode(
          utf8.encode('$username:$password'),
        );

    _session.sessionHeaders.addAll({
      'authorization': authCredentials,
    });

    http.Response tokenResponse = await _session.get('${baseUrl}token.html');

    String token = html.parse(tokenResponse?.body)?.getElementById('token')?.text;

    _session.token = token;

    log('[logIn] : statusCode : ${tokenResponse.statusCode}, response-body : ${tokenResponse.body}');

    return tokenResponse.statusCode == 200;
  }

    /// Logs out the current user
  void logOut() {
    _session.sessionHeaders = {};
  }

  /// Pass in the [torrentHash], i.e. hash of the torrent file
  /// to initiate it.
  /// Returns Future<http.Response>
  Future<http.Response> startTorrent(String torrentHash) async {
    assert(torrentHash != null);

    String url = '$baseUrl?action=start&hash=$torrentHash';
    http.Response response = await _session.get(url);

    return response;
  }

  
  /// Pass in the [torrentHashes], i.e. list of hashed of the
  /// torrents files to initiate them.
  ///
  /// Returns Future<http.Response>
  Future<http.Response> startTorrents(List<String> torrentHashes) async {
    assert(torrentHashes != null);
    assert(torrentHashes.length != 0); 

    String url = '$baseUrl?action=start';

    for (String torrentHash in torrentHashes) url += '&hash=$torrentHash';

    http.Response response = await _session.get(url);

    return response;
  }

  
  /// A list of torrents being held on the server
  Future<List<dynamic>> get torrentsList async {
    http.Response response = await _session.get('$baseUrl?list=1');

    log('[torrentsList] : statusCode : ${response.statusCode}, response-body: ${response.body}');

    return json.decode(response.body)['torrents'];
  }
}