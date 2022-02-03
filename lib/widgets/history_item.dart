import 'package:flutter/material.dart';

import '/models/history.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';

class HistoryItem extends StatelessWidget {
  const HistoryItem({Key? key, required this.history}) : super(key: key);
  final History history;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      'images/pickicon.png',
                      height: 16,
                      width: 16,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        child: Text(
                          history.pickUp,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      '\$${history.fares}',
                      style: const TextStyle(
                        fontFamily: 'Brand',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset(
                    'images/desticon.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 18),
                  Text(
                    history.dropOff,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                AssistantMethods.formatTripDate(history.createdAt),
                style: const TextStyle(color: Colors.grey),
              )
            ],
          ),
        ],
      ),
    );
  }
}
