import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:offline_menu_translator/domain/download_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HuggingFace access token. Gemma 4 E2B (litert-community) is a public,
/// non-gated model, so this can stay empty. Set it only if you switch to a
/// gated model that requires authentication.
final accessToken = "";

class GemmaDownloaderDataSource {
  final DownloadModel model;

  GemmaDownloaderDataSource({required this.model});

  String get _preferenceKey => 'model_downloaded_${model.modelFilename}';

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${model.modelFilename}';
  }

  Future<bool> checkModelExistence() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_preferenceKey) ?? false) {
      final filePath = await getFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        return true;
      }
    }

    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      final Map<String, String> headers = accessToken.isNotEmpty
          ? {'Authorization': 'Bearer $accessToken'}
          : {};
      final headResponse = await http.head(
        Uri.parse(model.modelUrl),
        headers: headers,
      );

      if (headResponse.statusCode == 200) {
        final contentLengthHeader = headResponse.headers['content-length'];
        if (contentLengthHeader != null) {
          final remoteFileSize = int.parse(contentLengthHeader);
          if (file.existsSync() && await file.length() == remoteFileSize) {
            await prefs.setBool(_preferenceKey, true);
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model existence: $e');
      }
    }
    await prefs.setBool(_preferenceKey, false);
    return false;
  }

  /// Downloads the model file and tracks progress.
  Future<void> downloadModel({
    required String token,
    required Function(double) onProgress,
  }) async {
    http.StreamedResponse? response;
    IOSink? fileSink;
    final prefs = await SharedPreferences.getInstance();

    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      final request = http.Request('GET', Uri.parse(model.modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        int received = downloadedBytes;

        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;
          onProgress(totalBytes > 0 ? received / totalBytes : 0.0);
        }
        await prefs.setBool(_preferenceKey, true);
      } else {
        await prefs.setBool(_preferenceKey, false);
        if (kDebugMode) {
          print(
            'Failed to download model. Status code: ${response.statusCode}',
          );
          print('Headers: ${response.headers}');
          try {
            final errorBody = await response.stream.bytesToString();
            print('Error body: $errorBody');
          } catch (e) {
            print('Could not read error body: $e');
          }
        }
        throw Exception('Failed to download the model.');
      }
    } catch (e) {
      await prefs.setBool(_preferenceKey, false);
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      rethrow;
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }
}
