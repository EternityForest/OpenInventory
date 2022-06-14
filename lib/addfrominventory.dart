import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:convert' as conv;
import 'dart:math';

Uint8List urandom(int l) {
  var random = Random.secure();
  return Uint8List.fromList(List<int>.generate(l, (i) => random.nextInt(256)));
}

class AddFromInventory extends StatefulWidget {
  const AddFromInventory({Key? key, required this.fn, required this.data, required this.target})
      : super(key: key);



  final String fn;
  final String data;

  final Map target;

  @override
  State<AddFromInventory> createState() => _AddFromInventoryState();
}

class _AddFromInventoryState extends State<AddFromInventory>
    with WidgetsBindingObserver {
  Map data = {};
  String fn = '';

  String newfn = '';
  String filter = '';

  List<Widget> shownItems = [];


  void doSKUList() {
    List<Widget> l = [];
    List<String> k = [];

    for(var i in data['sku'].keys)
    {
      if(i.runtimeType==String) {
        k.add(i);
      }
    }    k.sort();

    for (var i in k) {
      if (!i.contains(filter)) {
        if (!data['sku'][i]['title'].contains(filter)) {
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
                initialValue: data['sku'][i]['title']
              ),
              subtitle: const Text(''),
            ),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      if(!widget.target['sku'].containsKey(i)) {
                        widget.target['sku'][i] = data['sku'][i];
                      }

                    }, child: const Text("Copy this")),


                ElevatedButton(
                    onPressed: () async {
                    },
                    child: Text("SKU $i"))
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
    data = conv.jsonDecode(widget.data);
    data.putIfAbsent('sku', () => {});
    fn = widget.fn;
    newfn = fn;

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
                initialValue: newfn,
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
                  Row(children: [
                  ])
                ],
              ),
            )));
  }
}
