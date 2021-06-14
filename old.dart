import 'package:flutter/material.dart';

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

Future<List<String>> getData() async {
  final response = await http.Client()
      .get(Uri.parse('https://www.anekdot.ru/last/anekdot/'));
  List<String> texts = [];

  if (response.statusCode == 200) {
    var document = parse(response.body);
    var ctx = document
        .getElementsByClassName('col-left col-left-margin')
        .first
        .children
        .first
        .children
        .sublist(1);
    ctx.forEach((element) {
      if (element.className == 'topicbox') {
        texts.add(element.children.first.text);
      }
    });
  }
  return texts;
}

class _MyAppHeader {
  AppBar build() {
    return new AppBar(
      title: Text('Смешные Анекдоты'),
      backgroundColor: Colors.teal,
      centerTitle: false,
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final int index;
  final String text;
  _ItemsCard(this.index, this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: ListTile(
          title: Text('Анекдот$index'),
          subtitle: SizedBox(
            child: Text(text),
            height: 50,
          ),
          leading: Icon(
            Icons.align_horizontal_left_sharp,
            size: 30,
          ),
          trailing: IconButton(
              icon: Icon(Icons.add_box_outlined),
              onPressed: () => print('Added')),
          enabled: true,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => _ReadingPage(text, index)));
          },
        ));
  }
}

class _ItemsList extends StatefulWidget {
  static Future<List<_ItemsCard>> getItems() async {
    List<_ItemsCard> list = <_ItemsCard>[];
    (await getData()).forEach((element) {
      list.add(_ItemsCard(list.length + 1, element));
    });

    return list;
  }

  final __ItemsListState wigdetState = __ItemsListState();

  @override
  __ItemsListState createState() {
    return wigdetState;
  }
}

class __ItemsListState extends State<_ItemsList> {
  List<_ItemsCard> items = [];
  bool updateChecker = false;

  void updateList() async {
    print('waiting...');
    updateChecker = !updateChecker;

    var buffer = await _ItemsList.getItems();
    setState(() => items = buffer);

    updateChecker = !updateChecker;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.separated(
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, index) => items[index],
          separatorBuilder: (_, __) => Divider(
                color: Colors.teal,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
          itemCount: items.length),
    );
  }
}

class MyApp extends StatelessWidget {
  final _ItemsList itemsList = new _ItemsList();

  @override
  Widget build(BuildContext context) {
    itemsList.wigdetState.items = [
      _ItemsCard(1, 'Анекдот есть... но я не покажу ;)')
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      home: Scaffold(
          appBar: _MyAppHeader().build(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.teal,
            child: Icon(Icons.find_replace_outlined),
            onPressed: () async {
              if (!itemsList.wigdetState.updateChecker) {
                print('Button Clicked');
                itemsList.wigdetState.updateList();
              }
            },
          ),
          body: itemsList),
    );
  }
}

class _ReadingPage extends StatelessWidget {
  final String items;
  final int index;
  _ReadingPage(this.items, this.index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Анекдот$index'),
          backgroundColor: Colors.teal,
          centerTitle: false,
        ),
        body: ListView(
          children: [
            Text(
              items,
              style: TextStyle(fontSize: 18),
            )
          ],
          padding: EdgeInsets.all(15),
        ));
  }
}
