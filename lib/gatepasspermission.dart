// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GatePassPermissionPage extends StatefulWidget {
  final String scanData;

  const GatePassPermissionPage({super.key, required this.scanData});

  @override
  // ignore: library_private_types_in_public_api
  _GatePassPermissionPageState createState() => _GatePassPermissionPageState();
}

class _GatePassPermissionPageState extends State<GatePassPermissionPage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? gatePassData;
  bool isLoading = true;
  bool isUpdating = false;

  String? userId;
  String? gatePassDocumentId;

  @override
  void initState() {
    super.initState();
    fetchGatePassData();
  }

  Future<void> fetchGatePassData() async {
    try {
      print("Querying all users' GatePasses for UniqueId: ${widget.scanData}");

      final usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final currentUserId = userDoc.id;

        final gatePassSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('GatePasses')
            .where('UniqueId', isEqualTo: widget.scanData)
            .get();

        if (gatePassSnapshot.docs.isNotEmpty) {
          final gatePassDoc = gatePassSnapshot.docs.first;
          gatePassData = gatePassDoc.data();

          gatePassDocumentId = gatePassDoc.id;
          userId = currentUserId;

          final userDocSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

          if (userDocSnapshot.exists) {
            userData = userDocSnapshot.data();
            setState(() {
              isLoading = false;
            });
          }

          if (gatePassData?['expired'] == true) {
            _showErrorDialog("This gate pass has already expired.");
            return;
          }

          return;
        }
      }

      print("No documents found for GatePassId: ${widget.scanData}");
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateGatePassStatus(bool isAllowed) async {
    if (gatePassData == null ||
        isUpdating ||
        userId == null ||
        gatePassDocumentId == null) return;

    setState(() => isUpdating = true);

    try {
      final isOut = gatePassData?['out'] == 1;
      final isIn = gatePassData?['in'] == 1;

      if (isOut && isIn) {
        await _updateGatePassExpiryStatus(true);
        _showErrorDialog("This gate pass has already been completed.");
        return;
      }

      final gatePassCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('GatePasses');

      if (isAllowed) {
        if (!isOut) {
          await gatePassCollection.doc(gatePassDocumentId!).update({
            'out': 1,
            'realTimeOut': DateTime.now(),
          });
          _showSuccessDialog("Gate Pass allowed for OUT.");
        } else if (!isIn) {
          await gatePassCollection.doc(gatePassDocumentId!).update({
            'in': 1,
            'realTimeIn': DateTime.now(),
          });

          await _updateGatePassExpiryStatus(true);
          _showSuccessDialog("Gate Pass allowed for IN.");
        }
      } else {
        if (!isOut) {
          await gatePassCollection.doc(gatePassDocumentId!).set({
            'rejected': true,
          }, SetOptions(merge: true));
          await _updateGatePassExpiryStatus(true);
          _showSuccessDialog("Gate Pass has been Rejected.");
        } else {
          await gatePassCollection.doc(gatePassDocumentId!).set({
            'rejected': true,
          }, SetOptions(merge: true));
          await _updateGatePassExpiryStatus(false);
          _showSuccessDialog("Gate Pass has been Rejected.");
        }
      }
    } catch (e) {
      _showErrorDialog("Error updating gate pass: $e");
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> _updateGatePassExpiryStatus(bool expiredStatus) async {
    if (gatePassDocumentId != null) {
      final gatePassCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('GatePasses');
      await gatePassCollection.doc(gatePassDocumentId!).update({
        'expired': expiredStatus,
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRejectReasonDialog(
      BuildContext context, String userId, String gatePassId) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reason for Rejecting'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String rejectReason = reasonController.text.trim();

                if (rejectReason.isNotEmpty) {
                  await _updateGatePassStatus(false);
                  await _saveRejectReasonGuard(userId, gatePassId, rejectReason);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please provide a reason for rejection.'),
                  ));
                }
              },
              child: const Text('Submit'),
            )
          ],
        );
      },
    );
  }

  Future<void> _saveRejectReasonGuard(
      String userId, String gatePassId, String rejectReason) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('GatePasses')
          .doc(gatePassId)
          .update({
        'RejectReasonGuard': rejectReason,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save rejection reason: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gate Pass Permission',
            style: TextStyle(color: Colors.purple),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.purple),
        ),
        backgroundColor: Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData == null || gatePassData == null
            ? const Center(child: Text("No data available."))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
            child: Text(
            "${gatePassData?['gatepassType']} Gate Pass",
              style: const TextStyle(fontSize: 25),
            )),
        const SizedBox(height: 10),
        Center(child: const Text("for")),
        if (gatePassData?['out'] == 0)
    const Center(
        child: Text(
          "Going Out",
          style: TextStyle(fontSize: 25),
        ))
    else if (gatePassData?['in'] == 0 &&
    gatePassData?['out'] == 1)
    const Center(
    child: Text(
    "Getting In",
    style: TextStyle(fontSize: 25),
    )),
    const SizedBox(height: 10),
    Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8.0), // Rounded corners (adjust as needed)
      child: userData?['profilePic'] != null && userData?['profilePic'].isNotEmpty
          ? Image.network(
        userData?['profilePic'], // Dynamic profile picture URL
        width: 150.0, // Adjusted width
        height: 200.0, // Adjusted height
        fit: BoxFit.cover, // Ensures the image covers the container
      )
          : Image.asset(
        'assets/photo.png', // Placeholder image
        width: 150.0, // Adjusted width
        height: 200.0, // Adjusted height
        fit: BoxFit.cover, // Ensures the placeholder image covers the container
      ),
    ),

    ),
    const SizedBox(height: 10),
    _buildRow("Name", userData?['name']),
    _buildRow("Roll No.", userData?['rollNo']),

    // const Divider(
    // height: 30, thickness: 1, color: Colors.grey),
    _buildRow(
    "Time Out", _safeDateTime(gatePassData?['timeOut'])),
    _buildRow(
    "Time In", _safeDateTime(gatePassData?['timeIn'])),
    _buildRow("Purpose", gatePassData?['purpose']),
    _buildRow("Place", gatePassData?['place']),

    _buildRow("Contact No.", userData?['phone']),
                _buildRow("Remark", userData?['remark']),
    const SizedBox(height: 20),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [

      ElevatedButton(
        onPressed: isUpdating
            ? null
            : () => _showRejectReasonDialog(
          context,
          userId!,
          gatePassDocumentId!,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text("REJECT"),
      ),
      ElevatedButton(
        onPressed: isUpdating
            ? null
            : () => _updateGatePassStatus(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text("ALLOW"),
      ),
    ],
    ),
              ],
            ),
        ),
    );
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? "Not available",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }


  String _safeDateTime(dynamic timestamp) {
    if (timestamp == null) return "Not available";
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd/MM/yyyy, hh:mm a').format(date);
    } catch (e) {
      return "Invalid date";
    }
  }
}
