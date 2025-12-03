import 'package:flutter/material.dart';
import 'package:travelbuddy_final/utils/app_colors.dart';

class FareBreakdownSheet extends StatelessWidget {
  final dynamic routeData;

  const FareBreakdownSheet({super.key, required this.routeData});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> legs = routeData['legs'];
    final String totalFare = routeData['total_fare_formatted'];

    final paidLegs = legs.where((leg) => (leg['fare'] ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          const Text("Fare Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Prepare exact change for smoother travel.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),

          if (paidLegs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("This route is free!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            )
          else
            ...paidLegs.map((leg) {
              final String type = leg['route_type'] ?? 'Ride';
              final String name = leg['route_name'] ?? '';
              final String cleanName = name.replaceAll('Ride ', '').replaceAll(type, '').trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(AppColors.getIconByType(type), color: AppColors.getColorByType(type), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (cleanName.isNotEmpty)
                            Text(cleanName, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text("₱${(leg['fare'] as num).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),

          const Divider(height: 32),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(totalFare, style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50], elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Got it", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}