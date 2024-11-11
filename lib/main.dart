import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerModel(),
      child: TaskTrackerApp(),
    ),
  );
}

class TimerModel with ChangeNotifier {
  int _seconds;
  Timer? _timer;
  int _currentCycle = 1;
  int _totalCycles = 1;
  bool _isBreak = false;
  bool _allCyclesCompleted = false;

  TimerModel({int initialMinutes = 25}) : _seconds = initialMinutes * 60;

  int get seconds => _seconds;
  int get currentCycle => _currentCycle;
  int get totalCycles => _totalCycles;
  bool get isBreak => _isBreak;
  bool get allCyclesCompleted => _allCyclesCompleted;

  String get formattedTime =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}'
  ;

  void setTimer(int minutes) {
    _seconds = minutes * 60;
    notifyListeners();
  }

  void setCycles(int cycles) {
    _totalCycles = cycles;
    _currentCycle = 1;
    _allCyclesCompleted = false;
    notifyListeners();
  }

  void startTimer() {
    if (_timer?.isActive ?? false) {
      return; // Prevent multiple timers from running
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners();
      } else {
        timer.cancel();
        if (_isBreak) {
          if (_currentCycle < _totalCycles) {
            _isBreak = false;
            _currentCycle++;
            setTimer(25);
            startTimer();
          } else {
            _allCyclesCompleted = true;
            notifyListeners();
          }
        } else {
          _isBreak = true;
          setTimer(5);
          startTimer();
        }
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isBreak = false;
    _currentCycle = 1;
    _allCyclesCompleted = false;
    setTimer(25);
    notifyListeners();
  }

  void skipBreak() {
    if (_isBreak) {
      _timer?.cancel();
      _isBreak = false;
      if (_currentCycle < _totalCycles) {
        _currentCycle++;
        setTimer(25);
        startTimer();
      } else {
        _allCyclesCompleted = true;
      }
      notifyListeners();
    }
  }

  void skipWork() {
    if (!_isBreak) {
      _timer?.cancel();
      _isBreak = true;
      setTimer(5);
      startTimer();
      notifyListeners();
    }
  }
}

class TaskTrackerApp extends StatefulWidget {
  @override
  TaskTrackerAppState createState() => TaskTrackerAppState();
}

class TaskTrackerAppState extends State<TaskTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MainScreen(onThemeChanged: _toggleTheme),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const MainScreen({super.key, required this.onThemeChanged});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int selectedIndex = 0;
  bool isDarkMode = false;

  final List<Widget> _pages = <Widget>[
    const TaskListScreen(),
    const PomodoroTimerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker'),
        actions: [
          Switch(
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
              widget.onThemeChanged(value);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: PomodoroTimerWidget(),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.list),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.timer),
                selectedIcon: Icon(Icons.timer_outlined),
                label: Text('Pomodoro'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}

class PomodoroTimerWidget extends StatelessWidget {
  const PomodoroTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final timerModel = context.watch<TimerModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timerModel.isBreak ? 'Break' : 'Work',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            timerModel.formattedTime,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class PomodoroTimerScreen extends StatelessWidget {
  const PomodoroTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerModel = context.watch<TimerModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
      ),
      body: Center(
        child: timerModel.allCyclesCompleted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Congratulations! You have completed all cycles!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: timerModel.resetTimer,
                    child: const Text('Set New Cycles'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: timerModel.totalCycles,
                    items: List.generate(10, (index) => index + 1)
                        .map((cycles) => DropdownMenuItem(
                              value: cycles,
                              child: Text('$cycles Cycle(s)'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        timerModel.setCycles(value);
                      }
                    },
                  ),
                  Text(
                    timerModel.isBreak
                        ? 'Break: ${timerModel.formattedTime}'
                        : 'Work: ${timerModel.formattedTime}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: timerModel.startTimer,
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: timerModel.stopTimer,
                        child: const Text('Stop'),
                      ),
                      ElevatedButton(
                        onPressed: timerModel.resetTimer,
                        child: const Text('Reset'),
                      ),
                      if (timerModel.isBreak)
                        ElevatedButton(
                          onPressed: timerModel.skipBreak,
                          child: const Text('Skip Break'),
                        ),
                      if (!timerModel.isBreak)
                        ElevatedButton(
                          onPressed: timerModel.skipWork,
                          child: const Text('Skip Work'),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}


class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> with WidgetsBindingObserver {
  Map<DateTime, List<Task>> tasksByDate = {};
  DateTime selectedDay = DateTime.now();
  int defaultEnergy = 10;
  Map<String, int> energyByWeekday = {
    'Monday': 10,
    'Tuesday': 15,
    'Wednesday': 10,
    'Thursday': 10,
    'Friday': 10,
    'Saturday': 5,
    'Sunday': 5,
  };
  Map<DateTime, int> energyByDate = {};

  @override
  Widget build(BuildContext context) {
    List<Task> tasks = tasksByDate[selectedDay] ?? [];
    int remainingEnergy = energyByDate[selectedDay] ?? energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${selectedDay.day}.${selectedDay.month}.${selectedDay.year}',
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditEnergyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
            ),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(12.0),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white),
            ),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDay,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                this.selectedDay = selectedDay;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showEditTaskDialog(tasks[index]),
                  child: TaskTile(
                    task: tasks[index],
                    onTaskToggled: (value) {
                      setState(() {
                        tasks[index].isCompleted = value ?? false;
                      });
                    },
                    onTaskRemoved: () {
                      setState(() {
                        Task? removedTask = tasksByDate[selectedDay]?.removeAt(index);
                        if (removedTask != null) {
                          energyByDate[selectedDay] = (energyByDate[selectedDay] ?? energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy) + removedTask.weight;
                          if (energyByDate[selectedDay]! > (energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy)) {
                            energyByDate[selectedDay] = energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy;
                          }
                        }
                      });
                    },
                    onAddNote: () => _showAddNoteDialog(tasks[index]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: EnergyBar(remainingEnergy: remainingEnergy),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        splashColor: Colors.lightGreen,
        onPressed: _showAddTaskDialog,
        tooltip: 'Add New Task',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  String _getWeekdayName(DateTime date) {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
  }

  void _showEditTaskDialog(Task task) {
    String note = task.note ?? '';
    DateTime? taskDeadline = task.deadline;
    TimeOfDay? taskDeadlineTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Task: ${task.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Note'),
              controller: TextEditingController(text: note),
              onChanged: (value) {
                note = value;
              },
            ),
            Row(
              children: [
                const Text('Deadline: '),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: task.deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        taskDeadline = pickedDate;
                      });
                    }
                  },
                  child: Text(taskDeadline == null
                      ? 'Select Date'
                      : '${taskDeadline!.day}.${taskDeadline!.month}.${taskDeadline!.year}'),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Deadline Time: '),
                TextButton(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: task.deadline != null ? TimeOfDay.fromDateTime(task.deadline!) : TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      setState(() {
                        taskDeadlineTime = pickedTime;
                      });
                    }
                  },
                  child: Text(taskDeadlineTime == null
                      ? 'Select Time'
                      : '${taskDeadlineTime!.hour}:${taskDeadlineTime!.minute.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.note = note;
                if (taskDeadline != null && taskDeadlineTime != null) {
                  task.deadline = DateTime(
                      taskDeadline!.year, taskDeadline!.month, taskDeadline!.day, taskDeadlineTime!.hour, taskDeadlineTime!.minute);
                } else if (taskDeadline != null) {
                  task.deadline = taskDeadline;
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditEnergyDialog() {
    int newEnergy = energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Energy for the Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    activeTrackColor: Colors.greenAccent,
                    inactiveTrackColor: Colors.redAccent,
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withAlpha(32),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                  ),
                  child: Slider(
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: 'Energy: ${newEnergy.toString()}',
                    value: newEnergy.toDouble(),
                    onChanged: (newValue) {
                      setState(() {
                        newEnergy = newValue.toInt();
                      });
                    },
                  ).animate().move(duration: 500.ms, curve: Curves.easeInOut),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                energyByWeekday[_getWeekdayName(selectedDay)] = newEnergy;
                energyByDate[selectedDay] = newEnergy;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    String taskName = '';
    int taskWeight = 1;
    DateTime? taskDeadline;
    TimeOfDay? taskDeadlineTime;
    String taskNote = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Task Name'),
              onChanged: (value) {
                taskName = value;
              },
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Task Weight'),
              value: taskWeight,
              items: List.generate(5, (index) => index + 1)
                  .map((weight) => DropdownMenuItem(
                        value: weight,
                        child: Text('Weight: $weight'),
                      ))
                  .toList(),
              onChanged: (value) {
                taskWeight = value ?? 1;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Task Note'),
              onChanged: (value) {
                taskNote = value;
              },
            ),
            Row(
              children: [
                const Text('Deadline: '),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        taskDeadline = pickedDate;
                      });
                    }
                  },
                  child: Text(taskDeadline == null
                      ? 'Select Date'
                      : '${taskDeadline!.day}.${taskDeadline!.month}.${taskDeadline!.year}'),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Deadline Time: '),
                TextButton(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      setState(() {
                        taskDeadlineTime = pickedTime;
                      });
                    }
                  },
                  child: Text(taskDeadlineTime == null
                      ? 'Select Time'
                      : '${taskDeadlineTime!.hour}:${taskDeadlineTime!.minute.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasksByDate[selectedDay] = tasksByDate[selectedDay] ?? [];
                DateTime? finalDeadline;
                if (taskDeadline != null && taskDeadlineTime != null) {
                  finalDeadline = DateTime(taskDeadline!.year, taskDeadline!.month, taskDeadline!.day, taskDeadlineTime!.hour, taskDeadlineTime!.minute);
                } else if (taskDeadline != null) {
                  finalDeadline = taskDeadline;
                }
                tasksByDate[selectedDay]!.add(Task(taskName.isNotEmpty ? taskName : 'New Task', taskWeight, deadline: finalDeadline, note: taskNote));
                energyByDate[selectedDay] = (energyByDate[selectedDay] ?? energyByWeekday[_getWeekdayName(selectedDay)] ?? defaultEnergy) - taskWeight;
                if (energyByDate[selectedDay]! < 0) energyByDate[selectedDay] = 0;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(Task task) {
    String note = task.note ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for Task: ${task.name}'),
        content: TextField(
          controller: TextEditingController(text: note),
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Note'),
          onChanged: (value) {
            note = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.note = note;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String name;
  final int weight;
  bool isCompleted;
  DateTime? deadline;
  String? note;

  Task(this.name, this.weight, {this.isCompleted = false, this.deadline, this.note});
}

class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onTaskToggled;
  final VoidCallback onTaskRemoved;
  final VoidCallback onAddNote;

  const TaskTile({super.key, required this.task, required this.onTaskToggled, required this.onTaskRemoved, required this.onAddNote});

  Color getColorForWeight(int weight) {
    if (weight <= 2) return Colors.green;
    if (weight <= 4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: onTaskToggled,
      ),
      title: Text(
        task.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.deadline != null)
            Text('Deadline: ${task.deadline!.day}.${task.deadline!.month}.${task.deadline!.year} ${task.deadline!.hour}:${task.deadline!.minute.toString().padLeft(2, '0')}'),
          if (task.note != null && task.note!.isNotEmpty)
            Text('Note: ${task.note}'),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.note_add, color: Colors.blue),
            onPressed: onAddNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onTaskRemoved,
          ),
        ],
      ),
    );
  }
}

class EnergyBar extends StatelessWidget {
  final int remainingEnergy;

  const EnergyBar({super.key, required this.remainingEnergy});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Remaining Energy: $remainingEnergy',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          minHeight: 12.0,
          value: remainingEnergy / 20,
          backgroundColor: Colors.red,
          valueColor: AlwaysStoppedAnimation<Color>(
            remainingEnergy > 5 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }ffff
}
