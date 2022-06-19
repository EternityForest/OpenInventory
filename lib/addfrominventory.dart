import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:convert' as conv;
import 'dart:math';
import 'fsutil.dart' as fsutil;

Future<Map<String, Map>> getSKUList(String fn) async {
  Map<String, Map> d = {};

  //Important that we do all the loads in paralell p
  try {
    var x = await fsutil.ls("$fn/sku", false).toList();

    List<Future> l = [];
    for (var i in x) {
      l.add(fsutil.read(i[1]).then((value) {
        d[i[0].substring(0, i[0].length - 4)] = conv.jsonDecode(value);
      }, onError: (e) {
        print(e);
      }));
    }
    await Future.wait(l);
  } catch (e) {
    print(e);
  }

  return d;
}

Uint8List urandom(int l) {
  var random = Random.secure();
  return Uint8List.fromList(List<int>.generate(l, (i) => random.nextInt(256)));
}

class AddFromInventory extends StatefulWidget {
  const AddFromInventory(
      {Key? key,
      required this.fn,
      required this.target,
      required this.changeTracker})
      : super(key: key);

  final String fn;

  final Map target;

  final Map changeTracker;

  @override
  State<AddFromInventory> createState() => _AddFromInventoryState();
}

class _AddFromInventoryState extends State<AddFromInventory>
    with WidgetsBindingObserver {
  Map data = {};
  String fn = '';
  String filter = '';

  List<Widget> shownItems = [];

  void doSKUList() async {
    data = await getSKUList(fn);

    List<Widget> l = [];
    List<String> k = [];

    for (var i in data.keys) {
      if (i.runtimeType == String) {
        k.add(i);
      }
    }
    k.sort();

    for (var i in k) {
      if (!i.contains(filter)) {
        if (!data[i]['title'].contains(filter)) {
          continue;
        }
      }

      Widget c = Card(
          child: Column(children: [
        ListTile(
          leading: const Icon(Icons.list),
          title: TextFormField(
              decoration: const InputDecoration(
                labelText: '',
              ),
              initialValue: data[i]['title']),
          subtitle: const Text(''),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (!widget.target.containsKey(i)) {
                    widget.target[i] = data[i];
                    widget.changeTracker[i] = true;
                  }
                },
                child: const Text("Copy this")),
            ElevatedButton(
                onPressed: () async {},
                child: Text("SKU  ${i.substring(0, min(i.length, 40))}"))
          ],
        )
      ]));
      l.add(c);
    }
    setState(() {
      shownItems = l;
    });
  }

  @override
  void initState() {
    super.initState();
    fn = widget.fn;

    WidgetsBinding.instance.addObserver(this);

    doSKUList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Inventory Name',
                ),
                initialValue: fn,
              ),
            ),
            body: Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                      ),
                      initialValue: filter,
                      onChanged: (v) {
                        filter = v;
                        doSKUList();
                      }),
                  Expanded(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: ClampingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: shownItems,
                          ))),
                  Row(children: [])
                ],
              ),
            )));
  }
}
