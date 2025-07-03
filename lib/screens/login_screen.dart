import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth/sign_up.dart';
import 'auth/forget_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // This contains MainHomeScreen
import 'upload_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test FYP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savedRemember = prefs.getBool('rememberMe') ?? false;

    setState(() {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      rememberMe = savedRemember;
    });
  }



  bool rememberMe = false;
  bool obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/image/background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Semi-transparent overlay
          Container(
            color: const Color.fromARGB(77, 0, 0, 0), // replaces withOpacity(0.3)
          ),

          // Welcome Text
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black.withAlpha(128), // replaces withOpacity(0.5)
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Logo
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/image/Logo.jpg',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Login panel
          Positioned(
            top: 370,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Gmail/Phone No.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember me'),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("⚠️ 请填写邮箱和密码")),
                          );
                          return;
                        }

                        try {
                          final userCredential = await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: email, password: password);

                          // ✅ 记住我功能：保存或清除账号信息
                          final prefs = await SharedPreferences.getInstance();
                          if (rememberMe) {
                            await prefs.setString('email', email);
                            await prefs.setString('password', password);
                            await prefs.setBool('rememberMe', true);
                          } else {
                            await prefs.remove('email');
                            await prefs.remove('password');
                            await prefs.setBool('rememberMe', false);
                          }

                          // ✅ 登录成功跳转主页面
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainHomeScreen()),
                          );
                        } on FirebaseAuthException catch (e) {
                          String message = "登录失败，请重试";

                          if (e.code == 'user-not-found') {
                            message = '⚠️ 没有这个账号';
                          } else if (e.code == 'wrong-password') {
                            message = '⚠️ 密码错误';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ 出错了: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(227, 172, 180, 1),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Sign Up and Forgot Password
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                  const Text(
                    " | ",
                    style: TextStyle(fontSize: 30.0, color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgetPassword()),
                      );
                    },
                    child: const Text(
                      "Forget Password",
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}