import 'package:flutter/material.dart';

class AppColors {
  // Transport Modes
  static const Color jeepney = Color(0xFF2196F3); // Blue
  static const Color bus = Color(0xFFF44336);     // Red
  static const Color tricycle = Color(0xFFFFC107); // Amber
  static const Color walk = Color(0xFF9E9E9E);    // Gray
  static const Color van = Color(0xFF9C27B0);     // Purple

  // Status
  static const Color trafficHeavy = Color(0xFFD32F2F);
  static const Color trafficModerate = Color(0xFFF57C00);
  static const Color trafficLow = Color(0xFF4CAF50); // Green

  // Helper to get color by type string
  static Color getColorByType(String type) {
    switch (type.toUpperCase()) {
      case 'JEEPNEY':
      case 'JEEP': return jeepney;
      case 'BUS': return bus;
      case 'TRICYCLE':
      case 'TRICYCLE_RIDE': return tricycle;
      case 'VAN':
      case 'UV': return van;
      case 'WALK':
      case 'WALK_TRANSFER':
      case 'WALK_VIRTUAL': return walk;
      default: return Colors.blueGrey;
    }
  }

  // Helper for Icons
  static IconData getIconByType(String type) {
    switch (type.toUpperCase()) {
      case 'JEEPNEY':
      case 'JEEP': return Icons.directions_bus_outlined; // Jeep icon not standard, Bus is close
      case 'BUS': return Icons.directions_bus;
      case 'TRICYCLE':
      case 'TRICYCLE_RIDE': return Icons.electric_rickshaw; // Closest to tricycle
      case 'VAN': return Icons.airport_shuttle;
      case 'WALK': return Icons.directions_walk;
      default: return Icons.commute;
    }
  }
}