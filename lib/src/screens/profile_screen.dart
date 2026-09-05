import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';

class ProfileScreen extends StatefulWidget {
  final OdomateRepository repository;
  final VoidCallback onSettings;
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.onSettings,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Vehicle? vehicle;
  final userName = TextEditingController();
  final plate = TextEditingController();
  String? photoPath;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    vehicle = await widget.repository.loadVehicle();
    if (vehicle != null) {
      userName.text = vehicle!.userName;
      plate.text = vehicle!.plateNumber;
      photoPath = vehicle!.photoPath;
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) setState(() => photoPath = photo.path);
  }

  Future<void> _save() async {
    if (vehicle == null) return;
    await widget.repository.saveVehicle(
      vehicle!.copyWith(
        userName: userName.text.trim(),
        plateNumber: plate.text.trim(),
        photoPath: photoPath,
      ),
    );
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile tersimpan')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profile'),
      actions: [
        IconButton(
          onPressed: widget.onSettings,
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 52,
              backgroundImage: photoPath == null
                  ? null
                  : FileImage(File(photoPath!)),
              child: photoPath == null
                  ? const Icon(Icons.person, size: 52)
                  : null,
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Tambah foto'),
          ),
        ),
        TextField(
          controller: userName,
          decoration: const InputDecoration(labelText: 'Nama user'),
        ),
        TextField(
          controller: plate,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Plat nomor'),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Simpan profile')),
      ],
    ),
  );
}
