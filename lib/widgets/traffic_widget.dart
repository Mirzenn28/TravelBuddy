import 'package:flutter/material.dart';
import 'dart:async';

class TrafficWidget extends StatefulWidget {
  const TrafficWidget({Key? key}) : super(key: key);

  @override
  State<TrafficWidget> createState() => _TrafficWidgetState();
}

class _TrafficWidgetState extends State<TrafficWidget> {
  String _trafficLevel = 'Moderate';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTrafficLevel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateTrafficLevel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTrafficLevel() {
    final hour = DateTime.now().hour;
    String level;

    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      level = 'Heavy';
    } else if ((hour >= 6 && hour < 7) ||
        (hour > 9 && hour < 17) ||
        (hour > 19 && hour <= 21)) {
      level = 'Moderate';
    } else {
      level = 'Light';
    }

    if (mounted) {
      setState(() => _trafficLevel = level);
    }
  }

  Color _getTrafficColor() {
    switch (_trafficLevel) {
      case 'Light':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Heavy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTrafficDescription() {
    switch (_trafficLevel) {
      case 'Light':
        return 'Traffic is flowing smoothly';
      case 'Moderate':
        return 'Some congestion expected';
      case 'Heavy':
        return 'Heavy traffic, expect delays';
      default:
        return 'Traffic data unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getTrafficColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTrafficColor(),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.traffic, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traffic: $_trafficLevel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTrafficColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTrafficDescription(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
