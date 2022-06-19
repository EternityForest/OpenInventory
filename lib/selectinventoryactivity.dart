import 'package:flutter/material.dart';
import 'fsutil.dart' as fsutil;
import 'inventory.dart';

class InventorySelector extends StatefulWidget {
  const InventorySelector({Key? key}) : super(key: key);

  @override
  State<InventorySelector> createState() => _InventorySelectorState();
}

class _InventorySelectorState extends State<InventorySelector>
    with WidgetsBindingObserver {
  List<Widget> myLists = [];
  String filter = '';

  void updateLists() async {
    List lists = [];

    for (var fn in await fsutil.ls("", true).toList()) {
      String title = fn[0];

      if (!title.contains(filter)) {
        continue;
      }


      if (!title.contains(filter)) {
        continue;
      }
      Widget c = Card(
          child: Column(children: [
        ListTile(
          leading: const Icon(Icons.list),
          title: Text(title),
          subtitle: const Text(''),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, fn[0]);
                },
                child: const Text("Select"))
          ],
        )
      ]));

      lists.add([title, c]);
    }

    setState(() {
      lists.sort((dynamic a, dynamic b) {
        return a[0].compareTo(b[0]);
      });

      myLists = [];

      for (var i in lists) {
        myLists.add(i[1]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    updateLists();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the InventorySelector object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Select inventory to copy from"),
          actions: [],
        ),
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.

            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
              TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                  ),
                  initialValue: filter,
                  onChanged: (v) {
                    filter = v;
                    updateLists();
                  }),
              Expanded(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[] + myLists + [],
                      )))
            ])));
  }
}
