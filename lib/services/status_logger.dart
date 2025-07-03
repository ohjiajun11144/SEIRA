import 'package:cloud_firestore/cloud_firestore.dart';

class StatusLogger {
  static Future<void> logStatusUpdate({
    required DocumentReference reportRef,
    required String status,
    String by = 'system',
  }) async {
    print('🟢 正在写入 status_logs 给文档：${reportRef.path}'); //tiaoshi



    await reportRef.collection('status_logs').add({
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'by': by,
    });

    print('✅ status_logs 写入成功');//tiaoshi

  }
}
