
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

class BottomText extends StatelessWidget {
  const BottomText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 60, right: 60, bottom: 120),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text:
                "Easily find and access nearby services. Subscribe, reserve, and enter with ",
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryColor,
              ),
            ),
            children: [
              TextSpan(
                text: "Just a tap",
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
