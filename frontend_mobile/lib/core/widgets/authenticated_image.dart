import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../di/injection_container.dart';
import '../network/api_client.dart';
import '../utils/api_url.dart';

/// [Image.network] JWT göndermez; `/files/...` uçları için Dio + Authorization.
class AuthenticatedImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AuthenticatedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() async {
    final dio = sl<ApiClient>().dio;
    final resolved = resolveApiUrl(widget.url);
    final response = await dio.get<List<int>>(
      resolved,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('empty image');
    }
    return Uint8List.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Icon(Icons.broken_image_outlined, size: 24),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}
