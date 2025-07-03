import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 上传图片并返回下载 URL
  Future<String> uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child('images').child('$fileName.jpg');

    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 上传报告（返回 Firestore 的文档引用）
  Future<DocumentReference> uploadReport({
    required File imageFile,
    required String category,
  }) async {
    String imageUrl = await uploadImage(imageFile);

    final docRef = await _firestore.collection('reports').add({
      'image_url': imageUrl,
      'category': category,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return docRef;
  }
}
