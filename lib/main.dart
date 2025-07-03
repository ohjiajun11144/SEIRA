import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project1/screens/login_screen.dart';
import 'services/report_service.dart';
import 'services/report_dispatcher.dart';  //导入派发逻辑的文件


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}




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
      final reportService = ReportService();     //zheligaiguo follow my reportservice.dart
      _latestReportRef = await reportService.uploadReport(
        imageFile: _image!,
        category: 'fire', // 先写死分类，等 AI 同学代码做好再自动填

      );
      final dispatcher = ReportDispatcher();
      await dispatcher.dispatchReport(ReportCategory.fire); // 传入分类




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
          children: [            ElevatedButton(
            onPressed: () async {
              final dispatcher = ReportDispatcher();


              await dispatcher.markReportAsReceived(_latestReportRef!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ 状态已设为 received')),
              );
            },
            child: Text("测试: 设为 received"),
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
