import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project1/services/status_logger.dart';


enum ReportCategory {
  fire,
  traffic,
  environment,
}

class ReportDispatcher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // 派发指定分类的所有待处理报告
  Future<void> dispatchReport(ReportCategory category) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('category', isEqualTo: category.name)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'status': 'dispatched',
        'assigned_to': _getDepartmentByCategory(category),
      });

      // ✅ 如果你有 StatusLogger，要在这里调用：
       await StatusLogger.logStatusUpdate(
         reportRef: doc.reference,
         status: 'dispatched',
       );
    }

    print('✅ 所有 ${category.name} 报告已派发'); // ✅ 要放在 for 循环外
  }
  Future<void> markReportAsReceived(DocumentReference reportRef) async {
    await reportRef.update({'status': 'received'});
    await StatusLogger.logStatusUpdate(
      reportRef: reportRef,
      status: 'received',
    );
  }

  Future<void> markReportAsCompleted(DocumentReference reportRef) async {
    await reportRef.update({'status': 'completed'});
    await StatusLogger.logStatusUpdate(
      reportRef: reportRef,
      status: 'completed',
    );
  }

  // 根据分类返回对应的部门名称
  String _getDepartmentByCategory(ReportCategory category) {
    switch (category) {
      case ReportCategory.fire:
        return 'fire_department';
      case ReportCategory.traffic:
        return 'transport_department';
      case ReportCategory.environment:
        return 'environment_department';
    }
  }
}
