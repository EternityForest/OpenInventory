import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  SharedPreferences? prefs;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SharedPreferences.getInstance().then((value) {
      setState(() {
        prefs = value;
      });
    });
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
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back))
          ],
        ),
        body: Center(
            child: Visibility(
                visible: prefs != null,
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            hintText: 'Should be unique, if you are using SyncThing',
                            labelText: 'Username',
                          ),
                        initialValue: prefs?.getString('username') ?? 'user',
                        onSaved: (value) {
                          if(value!=null) {
                            prefs?.setString('username', value.replaceAll('/', '').replaceAll(' ','-'));
                          }
                        }
                      ),
                      ElevatedButton(
                          onPressed: () {
                            _formKey.currentState?.save();
                            Navigator.pop(context);
                          },
                          child: const Text("Save"))
                    ],
                  ),
                ))));
  }
}
