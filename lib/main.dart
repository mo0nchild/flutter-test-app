import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

const MaterialColor MyApp_MainColor = Colors.teal;
const String About =
    'Программа создана на основе "Flutter Framework".\n\nСоздатель: "Mo0nChild".\nВерсия: 0.2.0';
enum ItemTypes { Saved, Finded }

void main() => runApp(MyApp());

Future<List<String>> shareContext(String? item) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var items = prefs.getStringList('Items');
  prefs.setStringList('Items', []);

  if (item != null && items?.indexWhere((element) => element == item) == -1)
    items?.add(item);

  prefs.setStringList('Items', items!);
  return items;
}

Future<List<String>> deleleContext(String? item) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var items = prefs.getStringList('Items');
  prefs.clear();

  items?.removeWhere((element) => item == element);
  prefs.setStringList('Items', items!);

  return items;
}

void openReadPage(
    BuildContext context, dynamic items, String top, ItemTypes type) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) {
    if (type == ItemTypes.Finded)
      return _ReadingPage(items, top);
    else
      return _SavedContentPage(items, top);
  }));
}

Future<List<String>?> getData() async {
  try {
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
  } catch (e) {
    print('Finding Error: $e');
    return null;
  }
}

class _MyAppHeader {
  final String headerTitle;
  _MyAppHeader(this.headerTitle);

  AppBar build() {
    return new AppBar(
      title: Text(headerTitle),
      backgroundColor: MyApp_MainColor,
      centerTitle: false,
    );
  }
}

// ignore: must_be_immutable
class _ItemsCard extends StatelessWidget {
  final int index;
  final String text;
  final ItemTypes type;
  final Function callback;

  void myDialog(BuildContext ctx) => showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
            title: Text('Удалить?'),
            actions: [
              TextButton(
                  onPressed: () async {
                    callback(await deleleContext(text));
                  },
                  child: Text('Да')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Нет')),
            ],
          ));

  _ItemsCard(this.index, this.text, this.type, this.callback);

  @override
  Widget build(BuildContext context) {
    IconButton button = IconButton(onPressed: null, icon: Icon(null));

    if (type == ItemTypes.Finded) {
      button = IconButton(
          icon: Icon(Icons.add_box_outlined),
          onPressed: () async {
            print('Item Added');
            print(await shareContext(this.text));
          });
    }

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
          trailing: button,
          enabled: true,
          onTap: () => openReadPage(
              context,
              <Widget>[Text(text, style: TextStyle(fontSize: 18))],
              'Анекдот$index',
              ItemTypes.Finded),
          onLongPress: () async {
            if (type == ItemTypes.Saved) myDialog(context);
          },
        ));
  }
}

class _ItemsList extends StatefulWidget {
  static Future<List<_ItemsCard>> getItems() async {
    List<_ItemsCard> list = <_ItemsCard>[];

    List<String>? lists = await getData();
    lists?.forEach((element) {
      list.add(_ItemsCard(list.length + 1, element, ItemTypes.Finded, () {}));
    });

    return list;
  }

  final __ItemsListState wigdetState = __ItemsListState();

  @override
  __ItemsListState createState() => wigdetState;
}

class __ItemsListState extends State<_ItemsList> {
  List<_ItemsCard> items = [];
  bool updateChecker = false;

  void updateList() async {
    print('waiting...');
    updateChecker = !updateChecker;

    var buffer = await _ItemsList.getItems();
    if (buffer.isNotEmpty) setState(() => items = buffer);

    updateChecker = !updateChecker;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.separated(
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, index) => items[index],
          separatorBuilder: (_, __) => Divider(
                color: MyApp_MainColor,
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
  void initSharePref() async => await shareContext(null);

  @override
  Widget build(BuildContext context) {
    itemsList.wigdetState.items = [
      _ItemsCard(
          1, 'Анекдот есть... но я не покажу ;)', ItemTypes.Finded, () {})
    ];
    initSharePref();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Анекдоты',
      home: Scaffold(
          appBar: _MyAppHeader('Смешные Анекдоты').build(),
          drawer: _MyLeftSideDrawer(),
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

class _MyLeftSideDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            height: 100,
            child: _MyDrawerHeader(),
          ),
          _MenuButtons('Сохранёные Анекдоты', () async {
            List<String> itemsList = await shareContext(null);
            openReadPage(
                context, itemsList, 'Сохранёные Анекдоты', ItemTypes.Saved);
          }),
          _MenuButtons(
              'О Программе',
              () => openReadPage(
                  context,
                  <Widget>[
                    Text(
                      About,
                      style: TextStyle(fontSize: 18),
                    )
                  ],
                  'О Программе',
                  ItemTypes.Finded)),
        ],
      ),
    );
  }
}

class _MenuButtons extends StatelessWidget {
  final String text;
  final Function action;
  _MenuButtons(this.text, this.action);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(
          text,
          style: TextStyle(fontSize: 20),
        ),
        onTap: () => action(),
      ),
    );
  }
}

class _MyDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      child: Container(
        alignment: Alignment.topLeft,
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Colors.white,
            ),
            Text(
              'Параметры',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
              ),
            ),
          ],
        ),
      ),
      decoration: BoxDecoration(color: MyApp_MainColor),
    );
  }
}

class _ReadingPage extends StatefulWidget {
  final String top;
  final List<Widget> items;
  _ReadingPage(this.items, this.top);

  @override
  __ReadingPageState createState() => __ReadingPageState();
}

class __ReadingPageState extends State<_ReadingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _MyAppHeader(widget.top).build(),
        body: ListView(
          children: this.widget.items,
          padding: EdgeInsets.all(10),
          physics: BouncingScrollPhysics(),
        ));
  }
}

class _SavedContentPage extends StatefulWidget {
  final String top;
  final List<String> items;
  _SavedContentPage(this.items, this.top);

  @override
  __SavedContentPageState createState() => __SavedContentPageState();
}

class __SavedContentPageState extends State<_SavedContentPage> {
  List<Widget> widgets = [];
  @override
  void initState() {
    widget.items.forEach((element) {
      widgets.add(
          _ItemsCard(widgets.length + 1, element, ItemTypes.Saved, updatePage));
    });
    super.initState();
  }

  void updatePage(dynamic arg) async => setState(() {
        widgets.clear();
        Navigator.pop(context, false);

        arg.forEach((el) {
          widgets.add(
              _ItemsCard(widgets.length + 1, el, ItemTypes.Saved, updatePage));
        });
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _MyAppHeader(widget.top).build(),
        body: ListView.separated(
            physics: BouncingScrollPhysics(),
            itemBuilder: (_, index) => widgets[index],
            separatorBuilder: (_, __) => Divider(
                  color: MyApp_MainColor,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
            itemCount: widgets.length));
  }
}
