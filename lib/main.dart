import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final bool isCompleted;

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

  void addTodo(Todo todo) {
    if (!todos.any((t) => t.title == todo.title)) {
      todos.add(todo);
    }
    notifyListeners();
  }

  void removeTodo(Todo todo) {
    if (todos.contains(todo)) {
      todos.remove(todo);
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
                        return ListTile(
                          title: Text(todo.title),
                          subtitle: Text(todo.description),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              appState.removeTodo(todo);
                            },
                          ),
                        );
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
            child: Text('Create a new To-Do'),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                appState.printTodos();
              },
              child: Text('Print Todos'),
            ),
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
