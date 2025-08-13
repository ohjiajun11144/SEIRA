import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project1/services/status_logger.dart';

/// 枚举：报告的分类
enum ReportCategory {
  fire,
  traffic,
  environment,
  unknown, // 额外添加，防止模型返回不匹配的标签
}

/// 工具函数：将模型识别的标签字符串转为 ReportCategory 枚举
ReportCategory stringToReportCategory(String label) {
  switch (label.toLowerCase()) {
    case 'fire':
      return ReportCategory.fire;
    case 'traffic':
      return ReportCategory.traffic;
    case 'environment':
      return ReportCategory.environment;
    default:
      return ReportCategory.unknown;
  }
}

class ReportDispatcher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ 派发指定分类的所有待处理报告
  Future<void> dispatchReport(ReportCategory category) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('category', isEqualTo: category.name)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'status': 'received',
        'assigned_to': _getDepartmentByCategory(category),
      });

      // 日志记录（可选）
      await StatusLogger.logStatusUpdate(
        reportRef: doc.reference,
        status: 'received',
      );
    }

    print('✅ 所有 ${category.name} 报告已派发');
  }

  /// ✅ 将报告标记为 “received”
  Future<void> markReportAsReceived(DocumentReference reportRef) async {
    await reportRef.update({'status': 'received'});

    await StatusLogger.logStatusUpdate(
      reportRef: reportRef,
      status: 'received',
    );
  }

  /// ✅ 将报告标记为 “completed”
  Future<void> markReportAsCompleted(DocumentReference reportRef) async {
    await reportRef.update({'status': 'completed'});

    await StatusLogger.logStatusUpdate(
      reportRef: reportRef,
      status: 'completed',
    );
  }

  /// ✅ 根据报告分类返回对应的部门名称（可根据你 Firestore 数据结构更改）
  String _getDepartmentByCategory(ReportCategory category) {
    switch (category) {
      case ReportCategory.fire:
        return 'fire_department';
      case ReportCategory.traffic:
        return 'transport_department';
      case ReportCategory.environment:
        return 'environment_department';
      case ReportCategory.unknown:
      default:
        return 'unknown_department';
    }
  }
}
