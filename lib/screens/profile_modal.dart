import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../utils/extensions.dart';
import '../widgets/username_avatar.dart';
import 'skin_loadout_screen.dart';

class ProfileModal extends StatefulWidget {
  const ProfileModal({
    required this.user,
    required this.username,
    this.photoUrl,
    super.key,
  });

  final User user;
  final String username;
  final String? photoUrl;

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl ?? widget.user.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.profile, style: const TextStyle(fontFamily: 'SpellOfAsia')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              UsernameAvatar(
                username: widget.username,
                size: 80,
                tooltip: widget.username,
                imageUrl: _photoUrl,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploading ? null : () => _showChangePhotoSheet(l10n),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          12.0.spaceY,
          Text(
            widget.username,
            textAlign: TextAlign.center,
            style: GoogleFonts.onest(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          10.0.spaceY,
          Text(
            '${l10n.email}: ${widget.user.email ?? 'N/A'}',
            style: GoogleFonts.onest(),
          ),
          Text(
            '${l10n.displayName}: ${widget.user.displayName ?? 'N/A'}',
            style: GoogleFonts.onest(),
          ),
          16.0.spaceY,
          FilledButton.icon(
            onPressed: _openSkinLoadout,
            icon: const Icon(Icons.style_outlined),
            label: Text(l10n.skinLoadoutManageButton),
          ),
          10.0.spaceY,
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.signOut, style: GoogleFonts.onest(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePhotoSheet(AppLocalizations l10n) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.profileChangePhoto,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.profileCamera),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.profileGallery),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(l10n.cancel),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _handleImageSelection(source, l10n);
    }
  }

  Future<void> _handleImageSelection(
    ImageSource source,
    AppLocalizations l10n,
  ) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1500,
        maxHeight: 1500,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final rawBytes = await pickedFile.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        rawBytes,
        minHeight: 800,
        minWidth: 800,
        quality: 75,
      );

      final ref = FirebaseStorage.instance.ref().child('user_profiles/${widget.user.uid}.jpg');
      await ref.putData(
        Uint8List.fromList(compressed),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      await widget.user.updatePhotoURL(downloadUrl);
      await _firestoreService.updateUserPhoto(widget.user.uid, downloadUrl);

      if (!mounted) return;
      setState(() => _photoUrl = downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoUpdateError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _openSkinLoadout() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    Future.microtask(() {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SkinLoadoutScreen(userId: widget.user.uid),
        ),
      );
    });
  }
}
