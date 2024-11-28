
import 'package:chat/components/button.dart';
import 'package:chat/components/textField.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {

  final TextEditingController otpController = TextEditingController();

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
                        'Recover Account',
                        style: GoogleFonts.outfit(fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8,),
                      Text(
                        'OTP code has been sent to your email.'
                            'Please enter the OTP code below.',
                        style: GoogleFonts.outfit(fontSize: 14,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 20,),
                      TextFieldInput(
                        textEditingController: otpController,
                        fieldName: '',
                        hintText: 'Enter OTP code',
                      ),
                      const SizedBox(height: 28,),
                      MyButton(onTap: (){}, text: 'Verify'),
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
