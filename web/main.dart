import 'dart:html';
import 'package:hive/hive.dart';
import 'package:observable_ish/observable_ish.dart';

Map entries = {};
RxValue element = RxValue(initial: 'home');
var previousElement = 'placeholder';

void main() async {
  querySelector('#new').onClick.listen((event) { 
    previousElement = element.value;
    element.value = 'new-entry';
  });
  querySelector('#lock').onClick.listen((event) { 
    previousElement = element.value;
    element.value = 'lock-journal'; 
  });
  querySelector('#save').onClick.listen((event) {
    var title = (querySelector('#title') as InputElement).value;
    var content = (querySelector('#entry') as TextAreaElement).value;

    var date = DateTime.now().toLocal();
    var entry = Entry(title, content, date);
    entries[entries.length + 2] = entry;
    
    renderList();
    addItem(entry);

    previousElement = element.value;
    element.value = 'home';
  });
  querySelector('#lock-').onClick.listen((event) {
    var pwd = (querySelector('#pwd') as InputElement).value;
    lockJournal(pwd);
  });
  querySelector('#unlock').onClick.listen((event) { unlockJournal(); });

  element.onChange.listen((event) { 
    switch (element.value) {
      case 'home':
        querySelector('#$previousElement').classes.removeAll(['visible', 'fade-in']);
        querySelector('#$previousElement').classes.add('hidden');
        querySelector('#home').classes.addAll(['visible', 'fade-in']);
        querySelector('#home').classes.remove('hidden');
        break;
      case 'new-entry':
        querySelector('#$previousElement').classes.removeAll(['visible', 'fade-in']);
        querySelector('#$previousElement').classes.add('hidden');
        querySelector('#new-entry').classes.addAll(['visible', 'fade-in']);
        querySelector('#new-entry').classes.remove('hidden');
        break;
      case 'lock-journal':
        querySelector('#$previousElement').classes.removeAll(['visible', 'fade-in']);
        querySelector('#$previousElement').classes.add('hidden');
        querySelector('#lock-journal').classes.addAll(['visible', 'fade-in']);
        querySelector('#lock-journal').classes.remove('hidden');
        break;
      case 'view-entry':
        querySelector('#$previousElement').classes.removeAll(['visible', 'fade-in']);
        querySelector('#$previousElement').classes.add('hidden');
        querySelector('#view-entry').classes.addAll(['visible', 'fade-in']);
        querySelector('#view-entry').classes.remove('hidden');
        break;
    }
  });

  var box = await Hive.openBox('journal');
  var isStetup = box.get('setup').toString();
  if (isStetup == 'false') {
    initDatabase();
  }
  if (box.get('locked').toString() == 'true') {
    lockJournal(box.get('pwd').toString());
  } else {
    setList();
  }
}

void renderList() {
  querySelector('#list').innerHtml = '';
  entries.forEach((k, v) {
    querySelector('#empty').style.display = 'none';
    querySelector('#list').appendHtml('''<div class="card card--clear">
					<div class="card__content">
						<div class="grid">
							<div class="grid__column grid__column--8">
								<h5 class="title">${v.title}</h5>
								<span>${v.date}</span>
							</div>
							<div class="grid__column grid__column--4">
								<button class="button button--clear" id="view-$k">View</button>
								<button class="button button--filled button--tertiary" id="delete-$k">Delete</button>
							</div>
						</div>
					</div>
				</div>''');
    querySelector('#view-$k').onClick.listen((event) { 
      renderView(k);
      previousElement = element.value;
      element.value = 'view-entry';
    });
    querySelector('#delete-$k').onClick.listen((event) {
      deleteEntry(k);
    });
  });
}

void initDatabase() {
  var box = Hive.box('journal');
  box.put('setup', 'true');
  box.put('locked', 'false');
}

void setList() async {
  var box = await Hive.openBox('journal');
  var map = box.toMap();
  map.remove('locked');
  map.remove('pwd');
  
  map.forEach((key, value) {
    var obj = Entry(value['title'], value['content'], value['date']);
    entries[key] = obj;
  });
  renderList();
}

void addItem(Entry entry) async {
  var box = await Hive.openBox('journal');
  await box.put(entries.length + 1, entry.toMap());
}

void lockJournal(String pwd) async {
  querySelector('#journal-locked').style.display = 'block';
  querySelector('#list').style.display = 'none';

  var box = await Hive.openBox('journal');
  await box.put('pwd', pwd);
  await box.put('locked', 'true');
}

void unlockJournal() async {
  var box = await Hive.openBox('journal');
  var pwd = box.get('pwd');
  var inputPwd = (querySelector('#unlock-pwd') as InputElement).value;

  if (pwd == inputPwd) {
    querySelector('#list').style.display = 'block';
    querySelector('#journal-locked').style.display = 'none';
    setList();
    renderList();
    await box.put('locked', 'false');
  } else {
    window.alert('Incorrect Unlock Password');
  }
}

void renderView(key) {
  querySelector('#view-entry').innerHtml = '''<div class="grid">
				<div class="grid__column grid__column--9">
					<h1 class="title">${entries[key].title}</h1>
					<div style="height: 15px;"></div>
					<p>${entries[key].content}</p>
				</div>
				<div class="grid__column grid__column--3">
					<button class="button button--filled button--tertiary" id="view-delete">Delete</button>
				</div>
			</div>''';
  querySelector('#view-delete').onClick.listen((event) { deleteEntry(key); });
}

void deleteEntry(key) async {
  var confirm = window.confirm('Are you sure you want to delete this entry?');

  if (confirm == true) {
    var box = await Hive.openBox('journal');
    await box.delete(key);

    previousElement = element.value;
    element.value = 'home';
    window.location.reload();
  }
}

class Entry {
  String title;
  String content;
  DateTime date;

  Map<String, dynamic> toMap() => {'title': title, 'content': content, 'date': date};

  Entry(title, content, date) {
    this.title = title;
    this.content = content;
    this.date = date;
  }
}