import 'package:flutter/material.dart';

class WidgetUtils{

  static   Future showOKDialiog(BuildContext context,{required  String title, required String message}) =>  showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title:   Text(title),
          content:   Text(message),
          actions: <Widget>[
            
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
}