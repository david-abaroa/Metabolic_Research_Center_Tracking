import 'package:flutter/material.dart';

/// A filled star if tirzepatide was taken that day (outline otherwise),
/// wrapped in a small circle border if GAC was also taken that day.
class TirzGacBadge extends StatelessWidget {
  final bool tookTirzepatide;
  final bool tookGac;
  final double size;

  const TirzGacBadge({
    super.key,
    required this.tookTirzepatide,
    required this.tookGac,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final star = Icon(
      tookTirzepatide ? Icons.star : Icons.star_border,
      color: tookTirzepatide ? Colors.amber : Colors.grey.shade400,
      size: size,
    );
    if (!tookGac) return star;
    return Container(
      padding: EdgeInsets.all(size * 0.09),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.teal, width: 2),
      ),
      child: star,
    );
  }
}
