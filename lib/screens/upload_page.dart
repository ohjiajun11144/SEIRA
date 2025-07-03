import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/report_service.dart';
import '../services/report_dispatcher.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  DocumentReference? _latestReportRef;
  File? _image;
  bool _uploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _uploading = true;
    });

    try {
      final reportService = ReportService();
      _latestReportRef = await reportService.uploadReport(
        imageFile: _image!,
        category: 'fire', // 先写死分类，等 AI 同学代码做好再自动填
      );

      final dispatcher = ReportDispatcher();
      await dispatcher.dispatchReport(ReportCategory.fire);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 上传成功，资料已保存")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 上传失败: $e")),
      );
    }

    setState(() {
      _uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("拍照上传")),
      body: Center(
        child: _uploading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {

                if (_latestReportRef == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ 请先上传照片')),
                  );
                  return;
                }


                final dispatcher = ReportDispatcher();
                await dispatcher.markReportAsReceived(_latestReportRef!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ 状态已设为 received')),
                );
              },
              child: const Text("测试: 设为 received"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_latestReportRef == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ 请先上传照片')),
                  );
                  return;
                }

                final dispatcher = ReportDispatcher();
                await dispatcher.markReportAsCompleted(_latestReportRef!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ 状态已设为 completed')),
                );
              },
              child: const Text("测试: 设为 completed"),
            ),
            _image != null
                ? Image.file(_image!, height: 200)
                : const Icon(Icons.camera_alt, size: 100),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickAndUploadImage,
              child: const Text("拍照并上传"),
            ),
          ],
        ),
      ),
    );
  }
}
