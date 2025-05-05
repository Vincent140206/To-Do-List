import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/widget/Button.dart';
import 'package:to_do_list/widget/TextField.dart';

class Forgotpasswordpage extends StatefulWidget {
  const Forgotpasswordpage({super.key});

  @override
  State<Forgotpasswordpage> createState() => _ForgotpasswordpageState();
}

class _ForgotpasswordpageState extends State<Forgotpasswordpage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController reNewPassController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.1),
            Text(
              "Reset",
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Text(
              "Password",
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 0.10,),
            Text(
              "Silakan masukan data yang diperlukan untuk mengubah password anda!"
            ),
            SizedBox(height: screenHeight * 0.02,),
            CustomTextField(
                iconAssetPath: "assets/icons/email.png",
                label: "Email",
                isPassword: false,
                controller: emailController
            ),
            SizedBox(height: screenHeight * 0.02,),
            CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "Old Password",
                isPassword: true,
                controller: oldPassController
            ),
            SizedBox(height: screenHeight * 0.02,),
            CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "New Password",
                isPassword: true,
                controller: newPassController
            ),
            SizedBox(height: screenHeight * 0.02,),
            CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "Re Type New Password",
                isPassword: true,
                controller: reNewPassController
            ),
            SizedBox(height: screenHeight * 0.05,),
            CustomButton(
                text: "Reset Password",
                onPressed: () {},
                height: 48,
                width: double.infinity
            ),
          ],
        ),
      ),
    );
  }
}
