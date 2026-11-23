import 'package:flutter/material.dart';

/// Uses the original black-and-gold Panah logo supplied for the agency.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 140});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/panah_logo.webp',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
}
