import 'package:flutter/material.dart';

void main() {
  runApp(const IdaApp());
}

class IdaApp extends StatelessWidget {
  const IdaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDA - 아이다',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이다 (IDA)'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              '아이다에 오신 것을 환영합니다!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '아이 돌봄 매칭 플랫폼',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            Text(
              '회원가입 및 로그인 기능을 곧 개발할 예정입니다.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}