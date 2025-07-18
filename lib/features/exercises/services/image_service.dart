import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/exercises_response.dart';
import '../../../core/config/app_config.dart';

class ImageService {
  final ApiClient _apiClient;

  ImageService(this._apiClient);

  /// Carica la lista delle immagini disponibili
  Future<AvailableImagesResponse?> getAvailableImages() async {
    try {
      final response = await _apiClient.getAvailableImages();
      if (response is Map<String, dynamic>) {
        return AvailableImagesResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Errore nel caricamento delle immagini: $e');
      return null;
    }
  }

  /// Genera l'URL completo per un'immagine
  static String getImageUrl(String? imageName) {
    if (imageName == null || imageName.isEmpty) {
      return '';
    }
    return '${AppConfig.baseUrl}/serve_image.php?filename=$imageName';
  }

  /// Widget per visualizzare un'immagine GIF con fallback
  static Widget buildGifImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder(
        placeholder: placeholder,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(
          placeholder: placeholder,
          width: width,
          height: height,
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(
          errorWidget: errorWidget,
          width: width,
          height: height,
        ),
        httpHeaders: const {
          'Accept': 'image/gif,image/*,*/*;q=0.8',
        },
      ),
    );
  }

  /// Widget per visualizzare un'immagine GIF in un container con bordo
  static Widget buildGifImageCard({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Color? borderColor,
    double borderWidth = 1.0,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: buildGifImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  static Widget _buildPlaceholder({
    Widget? placeholder,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: placeholder ??
          Center(
            child: Icon(
              Icons.image,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
    );
  }

  static Widget _buildErrorWidget({
    Widget? errorWidget,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Immagine non disponibile',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
    );
  }
} 