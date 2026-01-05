import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvatarService {
  static Future<String> upload(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
