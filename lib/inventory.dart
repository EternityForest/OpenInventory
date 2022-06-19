import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert' as conv;
import 'dart:math';
import "fsutil.dart" as fsutil;
import 'dialogs.dart';
import 'selectinventoryactivity.dart';
import 'addfrominventory.dart' as addfrom;
import 'package:shared_preferences/shared_preferences.dart';

conv.JsonEncoder encoder = const conv.JsonEncoder.withIndent('  ');


Uint8List urandom(int l) {
  var random = Random.secure();
  return Uint8List.fromList(List<int>.generate(l, (i) => random.nextInt(256)));
}

// fn is actually the folder name
class InventoryHome extends StatefulWidget {
  const InventoryHome({Key? key, required this.fn})
      : super(key: key);

  final String fn;

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome>
    with WidgetsBindingObserver {

  Map<String, Map> sku= {};
  String fn = '';
  String newfn = '';

  String username = '';

  String selectedTally = '';

  Map<String, Map<String, num>> skuCount = {};
  Map userTallyData = {};

  bool userTallyDataChanged = false;

  String filter = '';
  bool shouldDelete = false;

  bool changed = false;

  Map<String,bool> skuMetaChanged = {};

  List<Widget> shownItems = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
      if (appLifecycleState == AppLifecycleState.detached) {
        save(newfn);
      }
  }



  Future<Map<String, Map>> getSKUList(String fn) async
  {
    Map<String, Map> d = {};

    //Important that we do all the loads in paralell p
    try{
      var x = await fsutil.ls("$fn/sku", false).toList();

      List<Future> l =[];
      for(var i in x){
        l.add(
            fsutil.read(i[1]).then((value){d[i[0].substring(0,i[0].length-5)]=conv.jsonDecode(value); })
        );
      }
      await Future.wait(l);
    }

    catch(e){
      print(e);
    }

    return d;
  }


  Future<void> doSKUList() async {
    //Only do this once
    if (username == '') {



      username =
          (await SharedPreferences.getInstance()).getString("username") ??
              'user';

      sku = await getSKUList(fn);

      var tallies = await fsutil.ls("$fn/tallies", true).toList();

      if (tallies.isEmpty) {
        DateTime now = DateTime.now();
        String isoDate = now.toIso8601String();

        await fsutil.saveStr("$fn/tallies/$isoDate/$username.json",
            encoder.convert(userTallyData));
        tallies = await fsutil.ls("$fn/tallies", true).toList();
      }

      tallies.sort((a,b) => a[0].compareTo(b[0]));

      selectedTally = tallies.last[0];

      if (await fsutil.exists("$fn/tallies/$selectedTally/$username.json")) {
        userTallyData = conv.jsonDecode(
            await fsutil.read("$fn/tallies/$selectedTally/$username.json"));
      }


      var f = await fsutil.ls(tallies.last[1], false).toList();

      for (var i in f ) {
        Map d =
        conv.jsonDecode(await fsutil.read(i[1]));
        d.putIfAbsent("sku", () => {});

        // The per user tally files are not absolutes, they are running tallies,
        // this is kind of a pseudo CRDT.

        for (String sku in d['sku'].keys) {
          skuCount.putIfAbsent(sku, () => {'stock': 0, 'checkedOut': 0});

          if (d['sku'][sku].containsKey('stock')) {
            skuCount[sku]?['stock'] =
                d['sku'][sku]['stock'] + (skuCount[sku]?['stock'] ?? 0);
          }
        }
      }
    }

    List<Widget> l = [];

    List<String> k = [];

    for (var i in sku.keys) {
      if (i.runtimeType == String) {
        k.add(i);
      }
    }
    k.sort();

    for (var i in k) {
      if (!i.contains(filter)) {
        if (!sku[i]?['title'].contains(filter)) {
          continue;
        }
      }

      num stock = 0;

      if (skuCount.containsKey(i)) {
        if (skuCount[i]?.containsKey('stock') ?? false) {
          stock = skuCount[i]?['stock'] ?? 0;
        }
      }
      try {
        Widget c = Card(
            child: Column(children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: TextFormField(
              decoration: const InputDecoration(
                labelText: '',
              ),
              initialValue: sku[i]?['title'] ?? '?????',
              onChanged: (v) {
                sku[i]?['title'] = v;
                skuMetaChanged[i]=true;
              },
            ),
            subtitle: const Text(''),
          ),
          Row(

              children: [

            ElevatedButton(
                onPressed: () async {}, child: Text("Stock: $stock")),
            IconButton(
                onPressed: () async {
                  // We must increment both the global running total and
                  // The user total, which is what we save so we can compute the
                  // global total in a distributed way

                  skuCount.putIfAbsent(i, () => {});
                  skuCount[i]?.putIfAbsent('stock', () => 0);
                  skuCount[i]?['stock'] = (skuCount[i]?['stock'] ?? 0) - 1;

                  userTallyData.putIfAbsent('sku', () => {});
                  userTallyData['sku'].putIfAbsent(i, () => {});
                  userTallyData['sku'][i]?.putIfAbsent('stock', () => 0);
                  userTallyData['sku'][i]?['stock'] =
                      (userTallyData['sku'][i]?['stock'] ?? 0) - 1;
                  userTallyDataChanged = true;
                  await doSKUList();
                },
                icon: const Icon(Icons.remove)),
            IconButton(
                onPressed: () async {
                  skuCount.putIfAbsent(i, () => {});
                  skuCount[i]?.putIfAbsent('stock', () => 0);
                  skuCount[i]?['stock'] = (skuCount[i]?['stock'] ?? 0) + 1;

                  userTallyData.putIfAbsent('sku', () => {});
                  userTallyData['sku'].putIfAbsent(i, () => {});
                  userTallyData['sku'][i]?.putIfAbsent('stock', () => 0);
                  userTallyData['sku'][i]?['stock'] =
                      (userTallyData['sku'][i]?['stock'] ?? 0) + 1;
                  userTallyDataChanged = true;
                 await doSKUList();
                },
                icon: Icon(Icons.add)),


                IconButton(onPressed: () async{
                  var r =await textPrompt(Navigator.of(context), "Really delete?",initialValue: 'yes');
                  if(r=='yes')
                  {
                    sku.remove(i);
                    skuMetaChanged[i]=true;
                    await doSKUList();
                  }
                }, icon: Icon(Icons.delete)),


              ]),
              ElevatedButton(
                  onPressed: () async {
                    String? s = await textPrompt(Navigator.of(context), "New SKU",
                        initialValue: i);
                    if (s == null) {
                      return;
                    }
                    var x = sku[i];
                    if(x==null)
                      {
                        return;
                      }
                    sku.remove(i);
                    sku[s] = x;
                    skuMetaChanged[i]=true;
                    skuMetaChanged[s]=true;
                    await doSKUList();
                  },
                  child: Text("SKU ${i.substring(0,min(i.length,40))}"))
        ]));
        l.add(c);
      } catch (e, s) {
        print(s);
      }
    }

    setState(() {
      shownItems = l;
    });

  }

  @override
  void initState() {
    super.initState();

    fn = widget.fn;
    newfn = fn;

    WidgetsBinding.instance.addObserver(this);
    doSKUList();
  }

  // Implement something resembling a terrible version of UNIX
  // Atomic rename on top of the terrible SAF.
  Future<void> save(String newbasename) async {
    if (userTallyDataChanged) {
      await fsutil.saveStr("$fn/tallies/$selectedTally/$username.json",
          encoder.convert(userTallyData));
    }

    if (!(fn.endsWith(newbasename))) {
      fsutil.rename(fn, newbasename);
    }

    List<Future> x=[];

    for(var i in skuMetaChanged.keys)
      {
        if(sku.containsKey(i)) {
          x.add(
              fsutil.saveStr("$fn/sku/$i.json", conv.jsonEncode(sku[i]))
          );
        }
        else
          {
            x.add(
            fsutil.delete("$fn/sku/$i.json")
            );
          }
      }

    skuMetaChanged.clear();
    changed=false;

    await Future.wait(x);
  }

  Future<void> delete() async {
    await fsutil.delete(fn);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          await save(newfn);
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
                onChanged: (v) {
                  changed = true;
                  newfn = v;
                },
              ),
              actions: [
                IconButton(
                    onPressed: () async {
                      NavigatorState n = Navigator.of(context);

                      await n.push(MaterialPageRoute(
                          builder: (c) => _SettingsPage(parent: this)));
                      if (shouldDelete) {
                        await delete();
                        n.pop();
                      }
                    },
                    icon: const Icon(Icons.settings))
              ],
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
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: shownItems,
                          ))),
                  Row(children: [
                    ElevatedButton(
                        onPressed: () async {
                          String? code;
                          NavigatorState n = Navigator.of(context);

                          while (true) {
                            code = await textPrompt(n, "SKU # or code",
                                initialValue: "000", barcodes: true);
                            if (code == null) {
                              return;
                            }
                            if (!sku.containsKey(code)) {
                              break;
                            }
                          }

                          String? title = await textPrompt(n, "Title");
                          if (title == null) {
                            return;
                          }

                          skuMetaChanged[code]=true;
                          sku[code] = {'title': title};
                          doSKUList();
                        },
                        child: const Text("New Row")),
                    ElevatedButton(
                        onPressed: () async {
                          NavigatorState n = Navigator.of(context);

                          String? inv = await n.push(MaterialPageRoute(
                              builder: (c) => const InventorySelector()));
                          if (inv == null) {
                            return;
                          }


                          await n.push(MaterialPageRoute(
                              builder: (c) => addfrom.AddFromInventory(
                                  fn: inv, target: sku, changeTracker: skuMetaChanged)));
                          doSKUList();
                        },
                        child: const Text("Import SKUs"))
                  ])
                ],
              ),
            )));
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({Key? key, required this.parent}) : super(key: key);

  final _InventoryHomeState parent;
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<_SettingsPage> createState() => __SettingsPageState();
}

class __SettingsPageState extends State<_SettingsPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Settings"),
          actions: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back))
          ],
        ),
        body: Center(
            child: Visibility(
                visible: true,
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                          onPressed: () async {
                            NavigatorState n = Navigator.of(context);
                            String? x = await textPrompt(n, "Really?",
                                initialValue: 'Yes');
                            if (x == 'Yes') {
                              widget.parent.shouldDelete = true;
                            }
                            n.pop();
                          },
                          child: const Text("Delete"))
                    ],
                  ),
                ))));
  }
}
