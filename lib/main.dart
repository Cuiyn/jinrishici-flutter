import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '今日诗词',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: '今日诗词'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _content = '';
  String _dynasty = '';
  String _author = '';
  String _origin = '';
  String _token;
  var _gushiJson;

  dynamic getJson(String url, bool ifToken) async {
    var httpClient = new HttpClient();
    var _response;
    try {
      if (ifToken) {
        // print('getJson(): $_token');
        var request = await httpClient.getUrl(Uri.parse(url))
          .then((HttpClientRequest request) {
            request.headers.set('X-User-Token', _token);
            return request;
          });
        _response = await request.close();
      } else {
        var request = await httpClient.getUrl(Uri.parse(url));
        _response = await request.close();
      }
      if (_response.statusCode == HttpStatus.ok) {
        var jsonStr = await _response.transform(utf8.decoder).join();
        var jsonData = json.decode(jsonStr);
        // print('getJson(): $jsonData');
        // print(jsonData['token']);
        return jsonData;
      }
    } catch (Exception) {
      return null;
    }
  }

  _getToken() async {
    if (_token == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.get('TOKEN');
      if (_token == null) {
        var httpClient = new HttpClient();
        String url = 'https://v2.jinrishici.com/token';
        try {
          var jsonData = await getJson(url, false);
          _token = jsonData['data'];
          // print('_getToken(): $_token');
          prefs.setString('TOKEN', _token);
        } catch (Exception) {
          // TODO
        }
      }
    }
  }

  void _getNewGushi() async {
    var httpClient = new HttpClient();
    String url = 'https://v2.jinrishici.com/one.json';
    await _getToken();
    try {
      var jsonData = await getJson(url, true);
      _gushiJson = jsonData;
      setState(() {
                _content = jsonData['data']['content'];
                _dynasty = jsonData['data']['origin']['dynasty'];
                _author = jsonData['data']['origin']['author'];
                _origin = jsonData['data']['origin']['title'];
              });
    } catch (Exception) {
      // TODO
    }
  }

  void _more() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('诗词全文'),
            ),
            body: Center(
              child: ListView(
                padding: EdgeInsets.all(8.0),
                children: <Widget>[
                  new Center(
                    child: Text(
                      '$_origin',
                      style: Theme.of(context).textTheme.title,
                    ),
                  ),
                  new Center(
                    child: Text(
                      '$_dynasty $_author',
                      style: Theme.of(context).textTheme.subtitle,
                    )
                  ),
                  new Center(
                    child: Text(
                      "${_gushiJson['data']['origin']['content']}"
                        .replaceFirst('[', '')
                        .replaceAll(']', '')
                        .replaceAll(' ', '')
                        .replaceAll(',', '\n'),
                      style: Theme.of(context).textTheme.subhead,
                    ),
                  ),
                  Text('\n'),
                  new Center(
                    child: Text(
                      "标签：${_gushiJson['data']['matchTags']}"
                        .replaceFirst('[', '')
                        .replaceAll(']', '')
                        .replaceAll(',', '，')
                        .replaceAll(' ', ''),
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                  Text('\n'),
                  new Center(
                    child: Text(
                      "释义：${_gushiJson['data']['origin']['translate']}"
                        .replaceAll('null', '（暂缺）')
                        .replaceFirst('[', '')
                        .replaceAll(']', '')
                        .replaceAll(',', '，')
                        .replaceAll(' ', ''),
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                ],
              ),             
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_content == '') {
      _getNewGushi();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.more), onPressed: _more)
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_content'
                .replaceAll('，', '，\n'),
              style: Theme.of(context).textTheme.display1,
            ),
            Text(
              '──$_dynasty $_author 《$_origin》',
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _getNewGushi,
        child: new Icon(Icons.refresh),
      ),
    );
  }
}
