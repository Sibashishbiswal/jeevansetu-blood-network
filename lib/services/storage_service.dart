import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donor.dart';
import '../models/sos_ticket.dart';

class StorageService {
  static const String _keyCurrentUser = 'jeevansetu_current_user';
  static const String _keyTickets = 'jeevansetu_sos_tickets';
  static const String _keyDonationHistory = 'jeevansetu_donation_history';

  static Future<void> saveUser(Donor donor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, json.encode(donor.toJson()));
    } catch (_) {}
  }

  static Future<Donor?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyCurrentUser);
      if (data != null && data.isNotEmpty) {
        return Donor.fromJson(json.decode(data) as Map<String, dynamic>);
      }
    } catch (_) {
      // Return null on parsing failure to allow fallback
    }
    return null;
  }

  static Future<void> saveTickets(List<SosTicket> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tickets.map((t) => t.toJson()).toList();
      await prefs.setString(_keyTickets, json.encode(jsonList));
    } catch (_) {}
  }

  static Future<List<SosTicket>?> loadTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyTickets);
      if (data != null && data.isNotEmpty) {
        final list = json.decode(data) as List<dynamic>;
        return list.map((e) => SosTicket.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  static Future<void> saveDonationHistory(List<DonationRecord> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((h) => h.toJson()).toList();
      await prefs.setString(_keyDonationHistory, json.encode(jsonList));
    } catch (_) {}
  }

  static Future<List<DonationRecord>?> loadDonationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyDonationHistory);
      if (data != null && data.isNotEmpty) {
        final list = json.decode(data) as List<dynamic>;
        return list.map((e) => DonationRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }
}
