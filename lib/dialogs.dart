import 'package:flutter/material.dart';

Future<String?> textPrompt(NavigatorState navigator, String prompt,{String initialValue:''}) async {
        var temp = initialValue;

        var d=  AlertDialog(
          title: const Text("Question"),
          content: TextFormField(
            onChanged: (value) {
              temp = value;
            },
            initialValue: initialValue,
            decoration: InputDecoration(labelText: prompt),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('CANCEL'),
              onPressed: () {
                navigator.pop(null);
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                navigator.pop(temp);
              },
            ),
          ],
        );

        return await navigator.push(
          MaterialPageRoute(
              builder: (context) => d),
        );
}
