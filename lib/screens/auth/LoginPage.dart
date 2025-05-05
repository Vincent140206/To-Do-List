import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widget/Button.dart';
import '../../widget/TextField.dart';
import '../HomeScreen.dart';
import 'ForgotPasswordPage.dart';
import 'SignUpPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.13),
              Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                "back!",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 0.10),
              Text(
                "Selamat datang! Silakan masukan email dan password anda untuk mengakses aplikasi ini!",
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                iconAssetPath: "assets/icons/email.png",
                label: 'Email',
                isPassword: false,
                controller: emailController,
              ),
              SizedBox(height: 20),
              CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "Password",
                isPassword: true,
                controller: passController,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    activeColor: Colors.red,
                    value: rememberMe,
                    onChanged: (bool? newValue) {
                      setState(() {
                        rememberMe = newValue ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 5),
                  Text("Remember me"),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Forgotpasswordpage(),
                        ),
                      );
                    },
                    child: Text("Forgot password?"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              CustomButton(
                text: "Sign In",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                },
                height: 48,
                width: double.infinity,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("Or"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 20),
              CustomButton(
                icon: Image.asset(
                  "assets/icons/google.png",
                  height: 24,
                  width: 24,
                ),
                backgroundColor: Colors.white,
                textColor: Colors.black,
                text: "Continue with Google",
                onPressed: () {},
                height: 48,
                width: double.infinity,
              ),
              SizedBox(height: 20),
              CustomButton(
                icon: Image.asset(
                  "assets/icons/facebook.png",
                  color: Colors.white,
                  height: 24,
                  width: 24,
                ),
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                text: "Continue with Facebook",
                onPressed: () {},
                height: 48,
                width: double.infinity,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
