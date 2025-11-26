import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.howToPlayTitle, style: TextStyle(fontFamily: 'SpellOfAsia')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.onitama,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onitamaDescription,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.objectiveTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.objectiveDescription,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.wayOfTheStone,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.wayOfTheStream,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.setupTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.setupDescription1,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.setupDescription2,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.setupDescription3,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.setupDescription4,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.gameplayTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.gameplayDescription,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.gameplayStep1,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.gameplayStep2,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.gameplayStep3,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.movementTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.movementDescription1,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.movementDescription2,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          Text(
            l10n.movementDescription3,
            style: GoogleFonts.onest(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.capturingTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpellOfAsia'),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.capturingDescription,
            style: GoogleFonts.onest(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
