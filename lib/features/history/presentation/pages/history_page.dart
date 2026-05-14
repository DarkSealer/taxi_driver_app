import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/features/trip_places/presentation/providers/trip_places_provider.dart';
import 'package:taxi_rider_app/widgets/history_item.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripPlacesProvider).tripHistoryDataList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return HistoryItem(history: trips[index]);
        },
        separatorBuilder: (_, __) => const Divider(thickness: 3, height: 3),
        itemCount: trips.length,
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
      ),
    );
  }
}
