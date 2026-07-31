import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final String? userName;
  final double? height;
  final double? width;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final BoxFit fit;
  final double radius;
  final Widget? errorWidget;
  final Color? placeholderBgColor;
  final Color? placeholderTextColor;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.userName,
    this.height,
    this.width,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.fit = BoxFit.cover,
    this.radius = 12,
    this.errorWidget,
    this.placeholderBgColor,
    this.placeholderTextColor,
  });

  static String getFormattedUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Replace backslashes with forward slashes
    url = url.replaceAll('\\', '/');

    String formattedUrl;
    if (url.startsWith('http')) {
      // If the database has hardcoded old URLs, point them to the current base
      final String baseWithoutSlash = ApiConstants.baseUrl2.endsWith('/')
          ? ApiConstants.baseUrl2.substring(0, ApiConstants.baseUrl2.length - 1)
          : ApiConstants.baseUrl2;
          
      formattedUrl = url.replaceFirst('http://88.222.245.145:4000', baseWithoutSlash);
      formattedUrl = formattedUrl.replaceFirst('https://toolucs.com', baseWithoutSlash);
      formattedUrl = formattedUrl.replaceFirst('https://toolbocs.apluscrm.in', baseWithoutSlash);
      formattedUrl = formattedUrl.replaceFirst('http://toolbocs.apluscrm.in', baseWithoutSlash);
      
      if (formattedUrl.startsWith('http://') && !formattedUrl.contains('localhost') && !formattedUrl.contains('127.0.0.1')) {
        formattedUrl = formattedUrl.replaceFirst('http://', 'https://');
      }
    } else {
      // Ensure exactly one slash between base and path
      final base = ApiConstants.baseUrl2.endsWith('/') 
          ? ApiConstants.baseUrl2 
          : '${ApiConstants.baseUrl2}/';
      final path = url.startsWith('/') ? url.substring(1) : url;
      formattedUrl = '$base$path';
    }

    // Attempt to parse the URL. If it succeeds, it will automatically encode spaces.
    try {
      return Uri.parse(formattedUrl).toString();
    } catch (e) {
      return Uri.encodeFull(formattedUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          imageUrl,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
        ),
      );
    }

    final absoluteUrl = getFormattedUrl(imageUrl);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Calculate memory cache dimensions if not provided but display dimensions are available.
    // IMPORTANT: To prevent Flutter's ResizeImage from distorting / stretching (`tedhi`) the 
    // bitmap in memory when both width & height are provided, we ONLY pass one dimension 
    // (calculatedMemCacheWidth OR calculatedMemCacheHeight) unless explicitly set by caller.
    // This guarantees the decoded image retains its true, natural aspect ratio (`straight`).
    final int? calculatedMemCacheWidth = memCacheWidth ??
        (width != null && width! > 0 && width!.isFinite && width != double.infinity
            ? (width! * pixelRatio).round()
            : null);
    final int? calculatedMemCacheHeight = memCacheHeight ??
        (memCacheWidth == null && calculatedMemCacheWidth == null && height != null && height! > 0 && height!.isFinite && height != double.infinity
            ? (height! * pixelRatio).round()
            : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: absoluteUrl,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: calculatedMemCacheWidth,
        memCacheHeight: calculatedMemCacheHeight,
        maxWidthDiskCache: maxWidthDiskCache ?? 1200,
        maxHeightDiskCache: maxHeightDiskCache ?? 1200,
        fadeOutDuration: const Duration(milliseconds: 200),
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => ShimmerBox(
          height: height ?? double.infinity,
          width: width ?? double.infinity,
          radius: radius,
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (userName != null && userName!.isNotEmpty) {
      return _buildLetterPlaceholder(context);
    }
    return errorWidget ??
        Container(
          height: height,
          width: width,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
  }

  Widget _buildLetterPlaceholder(BuildContext context) {
    final firstLetter = userName!.trim().isNotEmpty
        ? userName!.trim().substring(0, 1).toUpperCase()
        : '?';

    final double effectiveHeight = (height != null && height!.isFinite) ? height! : 40.0;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: placeholderBgColor ??
            Theme.of(context).primaryColor.withOpacity(0.1),
        shape: radius >= 40 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius >= 40 ? null : BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: placeholderTextColor ?? Theme.of(context).primaryColor,
          fontSize: effectiveHeight * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
