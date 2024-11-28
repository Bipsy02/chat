
import 'package:chat/components/button.dart';
import 'package:chat/components/textField.dart';
import 'package:chat/pages/otpPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Colors.black,
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
                  padding: const EdgeInsets.only(top: 34,left: 18, right: 20, bottom:24),
                  child: Column(
                    children: [
                      Text(
                        'Forgot Password',
                        style: GoogleFonts.outfit(fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8,),
                      Text(
                        'Enter your email',
                        style: GoogleFonts.outfit(fontSize: 14,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 20,),
                      TextFieldInput(
                        textEditingController: emailController,
                        fieldName: '',
                        hintText: 'Enter your email',
                      ),
                      const SizedBox(height: 28,),
                      MyButton(onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OtpPage()),
                        );
                      }, text: 'Send OTP code'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
