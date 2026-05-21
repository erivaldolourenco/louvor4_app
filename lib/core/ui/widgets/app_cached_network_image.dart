import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/url_utils.dart';

ImageProvider<Object>? appCachedImageProvider(String? imageUrl) {
  if (!UrlUtils.isValidNetworkUrl(imageUrl)) return null;
  return CachedNetworkImageProvider(imageUrl!);
}

class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, _) =>
          placeholder ??
          Container(width: width, height: height, color: placeholderColor),
      errorWidget: (_, _, _) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: placeholderColor,
            child: Icon(Icons.broken_image_outlined, color: AppColors.textMutedDark),
          ),
    );
  }
}
