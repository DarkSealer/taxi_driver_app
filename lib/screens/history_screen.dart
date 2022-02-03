import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/datahandler/appdata.dart';
import '/widgets/history_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(0),
        itemBuilder: (context, index) {
          return HistoryItem(
              history: Provider.of<AppData>(context, listen: false)
                  .tripHistoryDataList[index]);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(
          thickness: 3,
          height: 3,
        ),
        itemCount: Provider.of<AppData>(context, listen: false)
            .tripHistoryDataList
            .length,
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
      ),
    );
  }
}
