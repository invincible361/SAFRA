import 'dart:async';
import 'package:flutter/material.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  int countdown = 5;
  Timer? timer;
  bool isPressed = false;
  bool sosTriggered = false;

  void startTimer() {
    setState(() {
      isPressed = true;
      countdown = 5;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        t.cancel();
        triggerSOS();
      }
    });
  }

  void triggerSOS() {
    setState(() {
      sosTriggered = true;
    });

    // 🔴 Here you can add your actual SOS logic (e.g., sending alert, API call, SMS, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚨 SOS Alert Triggered!")),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPressed ? "Timer : 00 : 0$countdown sec" : "Press Button",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // SOS Button
            GestureDetector(
              onTap: () {
                if (!isPressed) {
                  startTimer();
                }
              },
              child: Container(
                height: 180,
                width: 180,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  "EMERGENCY\nSOS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (!sosTriggered)
              const Text(
                "After pressing the button\nEmergency Alert will be triggered\nin next 5 sec",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

            if (sosTriggered)
              const Text(
                "🚨 Emergency SOS Triggered!",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
