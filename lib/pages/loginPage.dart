
import 'package:chat/components/button.dart';
import 'package:chat/components/textField.dart';
import 'package:chat/pages/forgetPage.dart';
import 'package:chat/pages/registerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signIn() async {
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim()
      );

      Navigator.of(context).pop();

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage())
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Container(
            color: Colors.black,
            height: size.height,
            child: Column(
              children: [
                Image.asset("assets/images/crowdLinkLogo.png"),
                Expanded(
                  child: Container(
                    width: size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 34, left: 18, right: 20, bottom: 24),
                      child: Column(
                        children: [
                          Text(
                            'Log In',
                            style: GoogleFonts.outfit(fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8,),
                          Text(
                            'Enter a short Subtitle here',
                            style: GoogleFonts.outfit(fontSize: 14,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 20,),
                          TextFieldInput(
                            textEditingController: emailController,
                            fieldName: 'Email',
                            hintText: 'Enter your email',
                          ),
                          const SizedBox(height: 20,),
                          TextFieldInput(
                            textEditingController: passwordController,
                            fieldName: 'Password',
                            hintText: 'Enter your password',
                          ),
                          const SizedBox(height: 8,),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgetPage()),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28,),
                          MyButton(onTap: signIn, text: 'Log In'),
                          SizedBox(height: size.height/8,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Don\'t have an account? ',
                                style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}