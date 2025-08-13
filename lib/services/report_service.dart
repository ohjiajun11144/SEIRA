import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ 添加这一行，获取当前用户

class ReportService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 上传图片到 Firebase Storage 并返回下载 URL
  Future<String> uploadImage(File imageFile) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('report_images/$fileName.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// 上传完整报告数据到 Firestore
  Future<DocumentReference> uploadReport({
    required File imageFile,
    required String category,
    required String description,
    required String location,
    required String date,
    required String time,
  }) async {
    // 获取当前用户
    final user = FirebaseAuth.instance.currentUser;

    // 上传图片并获取 URL
    final imageUrl = await uploadImage(imageFile);

    // 写入 Firestore 的字段
    final reportData = {
      'userId': user?.uid ?? '', // ✅ 添加 userId 字段
      'image_url': imageUrl,
      'category': category,    //
      'description': description,
      'location': location,
      'date': date,
      'time': time,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'handledBy': '', // 后续 department_selection 中会处理
      'type': 'report', // ✅ 加上这一行！
    };

    // 创建文档并返回其引用
    return await _firestore.collection('reports').add(reportData);
  }

  /// 获取最新的报告（按时间戳降序排列，取第一个）
  Future<Map<String, dynamic>?> fetchLatestReport() async {
    final snapshot = await _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  /// 获取最新的3~4个报告（按时间戳降序排列，取前几个）
  Future<List<Map<String, dynamic>>> fetchLatestReports({int limit = 4}) async {
    final snapshot = await _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
