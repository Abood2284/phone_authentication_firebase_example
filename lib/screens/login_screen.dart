import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:phone_authentication_firebase_example/screens/home_screen.dart';

// To show enter mobile field OR enter otp field
enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Default state is enter mobile number
  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

// After the code is sent by firebase the verificationId is important so we save it in global variable
  String? verificationId;
// TO show the loading spinner
  bool showLoading = false;

// This methods signs the user in, It needs a PhoneAuthCredential variable type
  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showLoading = true;
    });

    try {
      // Sign in with the credential you got
      final authCredential =
          await _auth.signInWithCredential(phoneAuthCredential);

      setState(() {
        showLoading = false;
      });
// If user not null then pass the user in
      if (authCredential.user != null) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } on FirebaseAuthException {
      setState(() {
        showLoading = false;
      });

      // _scaffoldKey.currentState
      //     .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  getMobileFormWidget(context) {
    return Column(
      children: [
        const Spacer(),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            hintText: "Phone Number",
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              showLoading = true;
            });
// This method will verify the phone number, on hovering on [verifyPhoneNumber]
            await _auth.verifyPhoneNumber(
              // Pass the entered phone number
              phoneNumber: phoneController.text,
// Triggered when an SMS is auto-retrieved or the phone number has been instantly verified. The callback will receive an [PhoneAuthCredential] that can be passed to [signInWithCredential] or [linkWithCredential].
              verificationCompleted: (phoneAuthCredential) async {
                setState(() {
                  showLoading = false;
                });

                /// * Basically [phoneAuthCredential] is what we need to sign the user in, and this credential can be achieved 2 ways,
                /// 1 -> If android device auto-retrieved the sms and verifies the user instantly then you user dont need to enter otp you can just call here [signInWithPhoneAuthCredential()]
                ///
                /// 2 -> you want to sign in manually and want user to sign in then you have to get this [phoneAuthCredential] explicitly, by verificationId which you get when the code is send, and with that you can get the verificationId that will fetch the phoneAuthCredential for you and you can call [signInWithPhoneAuthCredential()] on the button where the otp is read
                signInWithPhoneAuthCredential(phoneAuthCredential);
              },
              // Triggered when an error occurred during phone number verification. A [FirebaseAuthException] is provided when this is triggered.
              verificationFailed: (firebaseException) async {
                setState(() {
                  showLoading = false;
                });
                // _scaffoldKey.currentState.showSnackBar(
                //     SnackBar(content: Text(firebaseException.message)));
              },
              //  Triggered when an SMS has been sent to the users phone, and will include a [verificationId] and [forceResendingToken].
              codeSent: (verificationId, resendingToken) async {
                setState(() {
                  showLoading = false;
                  currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                  this.verificationId = verificationId;
                });
              },
              codeAutoRetrievalTimeout: (verificationId) async {},
            );
          },
          child: const Text("SEND"),
        ),
        const Spacer(),
      ],
    );
  }

  getOtpFormWidget(context) {
    return Column(
      children: [
        const Spacer(),
        TextField(
          controller: otpController,
          decoration: const InputDecoration(
            hintText: "Enter OTP",
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        ElevatedButton(
          onPressed: () async {
            PhoneAuthCredential phoneAuthCredential =
                PhoneAuthProvider.credential(
                    verificationId: verificationId!,
                    smsCode: otpController.text);

            signInWithPhoneAuthCredential(phoneAuthCredential);
          },
          child: const Text("VERIFY"),
        ),
        const Spacer(),
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Container(
          child: showLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
                  ? getMobileFormWidget(context)
                  : getOtpFormWidget(context),
          padding: const EdgeInsets.all(16),
        ));
  }
}
