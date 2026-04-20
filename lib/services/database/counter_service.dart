import 'package:cloud_firestore/cloud_firestore.dart';

class CounterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the next sequential user ID in the format OPT-001, OPT-002...
  static Future<String> getNextUserSequentialId() async {
    final DocumentReference counterRef = _firestore.collection('_counters').doc('users');

    return await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);

      int currentCount = 0;
      if (snapshot.exists) {
        currentCount = snapshot.get('current') ?? 0;
      }

      int nextCount = currentCount + 1;
      
      // Update the counter in a transaction
      transaction.set(counterRef, {'current': nextCount});

      // Format the ID: OPT-001, OPT-002, etc.
      String formattedId = 'OPT-${nextCount.toString().padLeft(3, '0')}';
      return formattedId;
    });
  }
}
