// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guard_app/gatepasspermission.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guard_app/login.dart';
import 'package:guard_app/update_expired_status.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanData = "";
  int _rejectedCount = 0;
  int _completedCount = 0;
  int _studentsOutCount = 0;
  String _guardName = ''; // To store the guard's name

  @override
  void initState() {
    super.initState();
     checkAndUpdateExpiredGatePasses();
    _fetchGatePassStats();
    _fetchGuardName();
  }

  Future<void> _fetchGatePassStats() async {
    await checkAndUpdateExpiredGatePasses();
  try {
    int rejected = 0;
    int completed = 0;
    int outOnly = 0;

    // Fetch all user documents
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      // Fetch gatePasses subcollection for the user
      final gatePassesSnapshot = await userDoc.reference.collection('GatePasses').get();

      for (var gatePassDoc in gatePassesSnapshot.docs) {
        final data = gatePassDoc.data();
        // Check and count gate pass stats
        if (data['rejected'] == true) {
          rejected++;
        }
        if (data['out'] == 1 && data['in'] == 1) {
          completed++;
        }
        if (data['out'] == 1&& data['in']==0) {
          outOnly++;
        }
      }
    }

    // Update state
    setState(() {
      _rejectedCount = rejected;
      _completedCount = completed;
      _studentsOutCount = outOnly;
    });
  } catch (e) {
    print('Error fetching gate pass stats: $e');
  }
}


  // Fetch Guard's Name
  Future<void> _fetchGuardName() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
   
    if (userId != null) {
      try {
        // Fetching guard data (Assuming guard info is stored in a 'guards' collection)
        final docSnapshot = await FirebaseFirestore.instance.collection('guards').doc(userId).get();

        if (docSnapshot.exists) {
          setState(() {
            _guardName = docSnapshot.data()?['fullName'] ?? 'Guard'; // Default to 'Guard' if no name is found
          });
        } else {
          print("Guard data not found.");
        }
      } catch (e) {
        print("Error fetching guard data: $e");
      }
    }
  }

  // Scan QR Code
  Future<void> _scanCode() async {
    String barCodeScanResult;

    try {
      barCodeScanResult =
          await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barCodeScanResult = "Failed to Scan";
    }

    setState(() {
      _scanData = barCodeScanResult;
    });

    print(_scanData);

    if (_scanData != "-1") {
      // Redirect to GatePassPermissionPage
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => GatePassPermissionPage(scanData: _scanData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs
                      .clear();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuardLoginPage()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
          title: const Text(
            'DashBoard', 
            style: TextStyle(color: Color.fromARGB(255, 15, 37, 96)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color.fromARGB(255, 6, 6, 6)),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Text with Guard's Name
                if (_guardName.isNotEmpty)
                  Text(
                    'Welcome $_guardName',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 63, 12, 122),
                    ),
                  ),
                 SizedBox(height: MediaQuery.of(context).size.width * 0.02),
                
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Center(
                    child: IconButton(
                      onPressed: _scanCode,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                ),
                 SizedBox(height: MediaQuery.of(context).size.width * 0.03),
                Text(
                  'Scan Gate Pass',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 63, 12, 122),
                  ),
                ),
                 SizedBox(height: MediaQuery.of(context).size.width * 0.08),
                _buildStatusBox(' Gate Pass Completed', _completedCount, Colors.green),
                 SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                _buildStatusBox('Gate Pass Rejected', _rejectedCount, Colors.red),
                 SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                _buildStatusBox(' Student went Out', _studentsOutCount, Colors.blue),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusBox(String label, int count, Color textColor) {
    return Container(
      padding:  EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        color: Colors.grey.shade100,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize:MediaQuery.of(context).size.width * 0.05 ,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
           SizedBox(height: MediaQuery.of(context).size.width * 0.02),
          Text(
            '$count',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

