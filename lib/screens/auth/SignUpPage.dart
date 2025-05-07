import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../widget/Button.dart';
import '../../widget/SelectDate.dart';
import '../../widget/TextField.dart';
import 'Policy.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ttlController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController repassController = TextEditingController();
  DateTime? selectedDate;
  bool acceptedTerms = false;

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
              SizedBox(height: screenHeight * 0.1),
              const Text(
                "Create",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Text(
                "Account",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              const Text(
                "Silakan buat akun baru untuk mengakses aplikasi ini! Anda dapat menggunakan email atau akun Google Anda.",
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                iconAssetPath: "assets/icons/person.png",
                label: "Nama Lengkap",
                isPassword: false,
                controller: nameController,
              ),
              SizedBox(height: screenHeight * 0.02),
              DatePickerField(
                label: 'Tanggal Lahir',
                iconAssetPath: "assets/icons/calendar.png",
                firstDate: DateTime(1950),
                lastDate: DateTime(2025, 12, 31),
                onDateChanged: (date) {
                  print('Tanggal dipilih: $date');
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                iconAssetPath: "assets/icons/email.png",
                label: "Email",
                isPassword: false,
                controller: emailController,
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "Password",
                isPassword: true,
                controller: passController,
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                iconAssetPath: "assets/icons/password.png",
                label: "Re-enter Password",
                isPassword: true,
                controller: repassController,
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Checkbox(
                    activeColor: Colors.red,
                    value: acceptedTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        acceptedTerms = newValue ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 5),
                  RichText(
                    text: TextSpan(
                      text: "Saya setuju dengan ",
                      style: const TextStyle(color: Colors.black, fontSize: 10),
                      children: [
                        TextSpan(
                          text: "Syarat dan Ketentuan",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsPage(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(
                          text: " dan ",
                          style: TextStyle(color: Colors.black, fontSize: 10),
                        ),
                        TextSpan(
                          text: "Kebijakan Privasi",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomButton(
                text: "Create Account",
                onPressed: acceptedTerms ? () {
                  if (nameController.text.isEmpty || emailController.text.isEmpty || passController.text.isEmpty || repassController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                        content: Text("Semua field harus diisi",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  } else if (passController.text != repassController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password tidak cocok")),
                    );
                  } else {
                    print("Akun dibuat");
                  }
                } : null,
                height: 48,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}