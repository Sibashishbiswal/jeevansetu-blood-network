import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_ticket.dart';

class FirebaseSyncService {
  static bool _isFirebaseInitialized = false;
  static bool get isConnectedToCloud => _isFirebaseInitialized;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketSubscription;

  /// Check if Firebase was initialized in main()
  Future<void> init({required Function(List<SosTicket>) onRemoteTicketsUpdated}) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
        if (kDebugMode) {
          print('🔥 JeevanSetu: Connected to Firebase Cloud Firestore!');
        }

        // Subscribe to real-time SOS stream from Cloud Firestore
        _ticketSubscription = FirebaseFirestore.instance
            .collection('sos_tickets')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          final tickets = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return SosTicket.fromJson(data);
          }).toList();

          onRemoteTicketsUpdated(tickets);
        }, onError: (e) {
          if (kDebugMode) {
            print('⚠️ Firestore sync error: $e');
          }
        });
      } else {
        _isFirebaseInitialized = false;
        if (kDebugMode) {
          print('ℹ️ Firebase not yet initialized - running in offline-first local mode.');
        }
      }
    } catch (e) {
      _isFirebaseInitialized = false;
      if (kDebugMode) {
        print('ℹ️ Running in Offline-First Mode: $e');
      }
    }
  }

  /// Push an SOS ticket to Firebase Firestore
  Future<bool> publishTicket(SosTicket ticket) async {
    if (!_isFirebaseInitialized) return false;
    try {
      await FirebaseFirestore.instance
          .collection('sos_tickets')
          .doc(ticket.id)
          .set(ticket.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error publishing to Firestore: $e');
      return false;
    }
  }

  /// Update an existing SOS ticket with concurrency locking
  Future<bool> updateTicketStatus(
    String ticketId,
    TicketStatus newStatus, {
    String? donorName,
    String? donorPhone,
  }) async {
    if (!_isFirebaseInitialized) return false;
    try {
      final docRef = FirebaseFirestore.instance.collection('sos_tickets').doc(ticketId);

      // Atomic transaction to guarantee first-come-first-served concurrency lock
      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return false;

        final currentStatus = snapshot.data()?['status'] as String?;
        if (newStatus == TicketStatus.accepted && currentStatus != 'pending') {
          // Already claimed by another donor in real time!
          return false;
        }

        final updates = <String, dynamic>{
          'status': newStatus.name,
        };
        if (donorName != null) updates['acceptedDonorName'] = donorName;
        if (donorPhone != null) updates['acceptedDonorPhone'] = donorPhone;
        if (newStatus == TicketStatus.accepted) {
          updates['unitsFulfilled'] = FieldValue.increment(1);
          updates['acceptedAt'] = DateTime.now().toIso8601String();
        } else if (newStatus == TicketStatus.fulfilled) {
          updates['fulfilledAt'] = DateTime.now().toIso8601String();
        }

        tx.update(docRef, updates);
        return true;
      });
    } catch (e) {
      if (kDebugMode) print('Transaction error: $e');
      return false;
    }
  }

  void dispose() {
    _ticketSubscription?.cancel();
  }
}
