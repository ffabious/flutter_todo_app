import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle("ffabious' To-Do App");
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'ToDo App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const CompletePage(),
      ),
    );
  }
}

class Todo {
  final String title;
  final String description;
  bool isCompleted;

  Todo({
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}

class CompletePage extends StatefulWidget {
  const CompletePage({super.key});

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.syncTodos();
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const TodoListPage();
        break;
      case 1:
        page = const TodoCreatePage();
        break;
      default:
        throw UnimplementedError('Unknown page index: $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.list),
                      label: Text('To-Do List'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add),
                      label: Text('Create To-Do'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  extended: constraints.maxWidth >= 700,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(child: Container(child: page)),
            ],
          ),
        );
      },
    );
  }
}

class MyAppState extends ChangeNotifier {
  var todos = <Todo>[];

  void syncTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var todoStrings = prefs.getStringList('todos') ?? [];
    todos = todoStrings.map((todoString) {
      var parts = todoString.split('|');
      return Todo(
        title: parts[0],
        description: parts[1],
        isCompleted: parts[2] == 'true',
      );
    }).toList();
  }

  void addTodo(Todo todo) async {
    if (!todos.any((t) => t.title == todo.title)) {
      todos.add(todo);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
        'todos',
        todos
            .map((t) => '${t.title}|${t.description}|${t.isCompleted}')
            .toList(),
      );
    }
    notifyListeners();
  }

  void removeTodo(Todo todo) {
    if (todos.any((t) => t.title == todo.title)) {
      todos.removeWhere((t) => t.title == todo.title);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList(
          'todos',
          todos
              .map((t) => '${t.title}|${t.description}|${t.isCompleted}')
              .toList(),
        );
      });
    }
    notifyListeners();
  }

  void updateTodo(Todo todo, {String prevTitle = ""}) {
    if (prevTitle.isEmpty) {
      prevTitle = todo.title;
    }
    if (todos.any((t) => t.title == prevTitle)) {
      var index = todos.indexWhere((t) => t.title == prevTitle);
      todos[index] = todo;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList(
          'todos',
          todos
              .map((t) => '${t.title}|${t.description}|${t.isCompleted}')
              .toList(),
        );
      });
    }
    notifyListeners();
  }

  void printTodos() {
    for (var todo in todos) {
      print(
        'Todo: ${todo.title}, Description: ${todo.description}, Completed: ${todo.isCompleted}',
      );
    }
  }
}

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Center(
      child: Container(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Consumer<MyAppState>(
                  builder: (context, appState, child) {
                    if (appState.todos.isEmpty) {
                      return Center(child: Text('No To-Dos yet!'));
                    }
                    return ListView.builder(
                      itemCount: appState.todos.length,
                      itemBuilder: (context, index) {
                        var todo = appState.todos[index];
                        return TodoTile(todo: todo, appState: appState);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodoTile extends StatelessWidget {
  const TodoTile({super.key, required this.todo, required this.appState});

  final Todo todo;
  final MyAppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            todo.isCompleted ? Icons.check_circle : Icons.circle,
            color: todo.isCompleted ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            todo.isCompleted = !todo.isCompleted;
            appState.updateTodo(todo);
          },
        ),
        title: Text(todo.title),
        subtitle: Text(todo.description),
        trailing: IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.64,
                  child: TodoEditForm(todo: todo),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TodoCreateForm extends StatefulWidget {
  const TodoCreateForm({super.key});

  @override
  State<TodoCreateForm> createState() => _TodoCreateFormState();
}

class _TodoCreateFormState extends State<TodoCreateForm> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Create To-Do',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: titleController,
              autofocus: true,
              onSubmitted: (value) {
                focusNode.requestFocus();
              },
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              focusNode: focusNode,
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                appState.addTodo(
                  Todo(
                    title: titleController.text,
                    description: descriptionController.text,
                    isCompleted: false,
                  ),
                );
              },
              child: Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}

class TodoEditForm extends StatefulWidget {
  const TodoEditForm({super.key, this.todo});
  final Todo? todo;

  @override
  State<TodoEditForm> createState() => _TodoEditFormState();
}

class _TodoEditFormState extends State<TodoEditForm> {
  var titleController = TextEditingController();
  var descriptionController = TextEditingController();
  late FocusNode descFocusNode;
  late FocusNode saveFocusNode;

  @override
  void initState() {
    super.initState();
    descFocusNode = FocusNode();
    saveFocusNode = FocusNode();
    if (widget.todo != null) {
      titleController.text = widget.todo!.title;
      descriptionController.text = widget.todo!.description;
    }
  }

  @override
  void dispose() {
    descFocusNode.dispose();
    titleController.dispose();
    saveFocusNode.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deleteTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        errorContainer: Colors.red.shade200,
        onErrorContainer: Colors.white,
      ),
    );
    var saveTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        primaryContainer: Colors.green.shade200,
        onPrimaryContainer: Colors.white,
      ),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Edit To-Do', style: Theme.of(context).textTheme.displaySmall),
          SizedBox(height: 16),
          SizedBox(
            width: 0.64 * MediaQuery.of(context).size.width,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              controller: titleController,
              autofocus: true,
              onSubmitted: (value) {
                descFocusNode.requestFocus();
              },
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 0.64 * MediaQuery.of(context).size.width,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              controller: descriptionController,
              focusNode: descFocusNode,
              onSubmitted: (value) {
                saveFocusNode.requestFocus();
              },
            ),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 0.16 * MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      deleteTheme.colorScheme.errorContainer,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      deleteTheme.colorScheme.error,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.focused)
                          ? deleteTheme.colorScheme.onErrorContainer
                          : deleteTheme.colorScheme.error,
                    ),
                  ),
                  onPressed: () {
                    var appState = context.read<MyAppState>();
                    if (widget.todo != null) {
                      appState.removeTodo(widget.todo!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              'To-Do "${widget.todo!.title}" deleted!',
                            ),
                          ),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Delete'),
                ),
              ),
              SizedBox(width: 32),
              SizedBox(
                width: 0.16 * MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      saveTheme.colorScheme.primaryContainer,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      saveTheme.colorScheme.primary,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.focused)
                          ? saveTheme.colorScheme.onPrimaryContainer
                          : saveTheme.colorScheme.primary,
                    ),
                  ),
                  focusNode: saveFocusNode,
                  onPressed: () {
                    var appState = context.read<MyAppState>();
                    appState.updateTodo(
                      Todo(
                        title: titleController.text,
                        description: descriptionController.text,
                        isCompleted: widget.todo?.isCompleted ?? false,
                      ),
                      prevTitle: widget.todo?.title ?? "",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            'To-Do "${titleController.text}" updated!',
                          ),
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TodoCreatePage extends StatelessWidget {
  const TodoCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      body: Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(child: TodoCreateForm()),
      ),
    );
  }
}
