import 'package:flutter/material.dart';
import 'package:shared_storage/saf.dart' as saf;
import 'settings.dart' as settings;
import 'fsutil.dart' as fsutil;
import 'inventory.dart';
import 'dialogs.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<Widget> myLists = [];
  String filter = '';

  void updateLists() async {
    List lists = [];

    Uri? root = (await fsutil.getAndroidFolder())?.uri;
    if (root == null) {
      return;
    }

    for (var fn in await fsutil.ls("", true).toList()) {
        String title = fn[0];

        if(! title.contains(filter))
        {
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
                    final navigator =
                        Navigator.of(context); // store the Navigator


                    navigator
                        .push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  InventoryHome(fn: fn[0])),
                        )
                        .then((value) => updateLists());
                  },
                  child: const Text("View/edit"))
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
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("OpenFlatInventory"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const settings.SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings))
          ],
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
              ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    String? n =
                        await textPrompt(navigator, "New inventory name");

                    if (n == null) {
                      return;
                    }

                    await navigator.push(
                      MaterialPageRoute(
                          builder: (context) =>
                              InventoryHome(fn: n)),
                    );
                    updateLists();
                  },
                  child: const Text("Add Inventory")),
              Expanded(
                  child:SingleChildScrollView(
                scrollDirection: Axis.vertical,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                children: <Widget>[] + myLists + [],
              )
              ))
            ])));
  }
}
