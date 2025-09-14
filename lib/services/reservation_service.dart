import 'package:flutter/material.dart';
import 'package:reservator/models/reservation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReservationService {
  static final instance = ReservationService._();
  ReservationService._();

  static const String _storageKey = 'reservations';
  bool _isInitialized = false;

  Future<void> init() async {
    if(_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? reservationsJson=prefs.getString(_storageKey);

      if(reservationsJson != null)
      {
        final List<dynamic> jsonList = json.decode(reservationsJson);
        _reservations.clear();
        _reservations.addAll(jsonList.map((json) => Reservation.fromJson(json)).toList());

        print("${_reservations.length} réservations chargées");
      }
    } catch(e) {
      print("Erreur chargement reservations : $e");
    }

    _isInitialized = true;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = 
          _reservations.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      print('Saved ${_reservations.length} reservations');
    } catch (e) {
      print('Error saving reservations: $e');
    }
  }

  final List<Reservation>_reservations = [];

  final List<VoidCallback> _listeners = [];

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  void addReservation(Reservation reservation) async {
    _reservations.add(reservation);
    _notifyListeners();
    await _saveToStorage();
  }

  void removeReservation(Reservation reservation) async {
    _reservations.remove(reservation);
    _notifyListeners();
    await _saveToStorage();
  }

  bool isEventReserved(String ticketId, String bookingUrl) {
    return _reservations.any((r) => r.ticketId == ticketId && r.bookingUrl == bookingUrl);
  }

  Reservation? getReservationForTicket(String tickedId) {
    try {
      return _reservations.firstWhere((r) => r.ticketId == tickedId);
    } catch (e) {
      return null;
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}