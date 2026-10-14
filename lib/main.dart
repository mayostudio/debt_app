import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rhind ERP',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
        cardColor: const Color(0xFF1E1E1E), 
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const LifeDashboardScreen(),
    const ProjectsScreen(), 
    const WalletScreen(), 
    const TasksTargetsScreen(), 
    const CreditorsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'), 
          BottomNavigationBarItem(icon: Icon(Icons.architecture), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Vault'), 
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Targets'), 
          BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'Debts'),
        ],
      ),
    );
  }
}

// ================== 1. Dashboard ==================
class LifeDashboardScreen extends StatefulWidget {
  const LifeDashboardScreen({super.key});
  @override
  State<LifeDashboardScreen> createState() => _LifeDashboardScreenState();
}

class _LifeDashboardScreenState extends State<LifeDashboardScreen> {
  Map stats = {};
  bool isLoading = true;
  String selectedFilter = 'all'; 

  @override
  void initState() { super.initState(); fetchStats(); }

  Future<void> fetchStats() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://rhind-backend.vercel.app/dashboard/stats?period=$selectedFilter'));
      if (response.statusCode == 200) setState(() { stats = json.decode(utf8.decode(response.bodyBytes)); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(color: const Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 40), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 5), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))])));
  }

  @override
  Widget build(BuildContext context) {
    String formattedHours = "0h";
    if (!isLoading && stats['total_hours'] != null) { int totalMins = (double.parse(stats['total_hours'].toString()) * 60).round(); formattedHours = '${totalMins ~/ 60}h ${totalMins % 60}m'; }
    return Scaffold(
      appBar: AppBar(title: Image.asset('assets/logo.png', height: 40), centerTitle: true),
      body: RefreshIndicator(
        color: Colors.greenAccent, backgroundColor: Colors.black, onRefresh: fetchStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoading) const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Colors.greenAccent)))
              else ...[
                Card(color: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.yellowAccent)), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.account_balance, color: Colors.yellowAccent, size: 40), const SizedBox(height: 10), const Text('Vault Balance (All Time)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)), Text('${stats['vault_balance'] ?? 0} EGP', style: const TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.bold))]))),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _buildStatCard('Income', '${stats['total_income'] ?? 0} EGP', Icons.account_balance_wallet, Colors.greenAccent)), const SizedBox(width: 10), Expanded(child: _buildStatCard('Time', formattedHours, Icons.access_time, Colors.orangeAccent))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _buildStatCard('Active Projects', '${stats['total_projects'] ?? 0}', Icons.architecture, Colors.blueAccent)), const SizedBox(width: 10), Expanded(child: _buildStatCard('Debts Due', '${stats['total_debt'] ?? 0} EGP', Icons.money_off, Colors.redAccent))]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================== 2. Projects Screen ==================
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List projects = []; bool isLoading = true;
  @override void initState() { super.initState(); fetchProjects(); }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('https://rhind-backend.vercel.app/projects/list'));
      if (response.statusCode == 200) setState(() { projects = json.decode(utf8.decode(response.bodyBytes)); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  Future<void> deleteProject(int id) async {
    setState(() => isLoading = true); await http.delete(Uri.parse('https://rhind-backend.vercel.app/projects/$id')); fetchProjects(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Projects', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
        : projects.isEmpty ? const Center(child: Text('No Projects Yet.', style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(10), itemCount: projects.length,
                itemBuilder: (context, index) {
                  final p = projects[index];
                  Color statusColor = p['status'] == 'Active' ? Colors.greenAccent : (p['status'] == 'Hold' ? Colors.orangeAccent : Colors.white);
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Icon(Icons.architecture, color: statusColor, size: 40),
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 5), Text('${p['company']} | Manager: ${p['project_manager']}', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text('Status: ${p['status']}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))]),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => deleteProject(p['id'])),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectWorkspaceScreen(project: p))).then((_) => fetchProjects()),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProjectScreen())).then((_) => fetchProjects()),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Project', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AddProjectScreen extends StatefulWidget {
  final Map? existingProject;
  const AddProjectScreen({super.key, this.existingProject});
  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final Map<String, TextEditingController> _ctrls = {
    'name': TextEditingController(), 'desc': TextEditingController(), 'allocTime': TextEditingController(), 'deadline': TextEditingController(), 'start': TextEditingController(), 'end': TextEditingController(), 'manager': TextEditingController(), 'company': TextEditingController(), 'customer': TextEditingController(), 'dailyHours': TextEditingController(text: "0"),
  };
  List<Map<String, dynamic>> reqs = [{'name': TextEditingController(), 'cost': TextEditingController(), 'status': 'Needed'}];

  @override
  void initState() {
    super.initState();
    if (widget.existingProject != null) {
      final p = widget.existingProject!;
      _ctrls['name']!.text = p['name'] ?? ''; _ctrls['desc']!.text = p['description'] ?? '';
      _ctrls['allocTime']!.text = p['allocated_time'] ?? ''; _ctrls['deadline']!.text = p['deadline'] ?? '';
      _ctrls['start']!.text = p['start_time'] ?? ''; _ctrls['end']!.text = p['end_time'] ?? '';
      _ctrls['manager']!.text = p['project_manager'] ?? ''; _ctrls['company']!.text = p['company'] ?? '';
      _ctrls['customer']!.text = p['customer'] ?? ''; _ctrls['dailyHours']!.text = (p['daily_hours_needed'] ?? 0).toString();
      reqs.clear(); 
    }
  }

  Widget _buildField(String key, String label, {int lines = 1}) { return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: _ctrls[key], maxLines: lines, decoration: InputDecoration(labelText: label))); }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.existingProject != null;
    double totalCost = reqs.where((r) => r['status'] == 'Needed').fold(0.0, (sum, r) => sum + (double.tryParse(r['cost'].text) ?? 0.0));
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Project' : 'Create New Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('name', 'Project Name *'),
            _buildField('desc', 'Description', lines: 3),
            Row(children: [Expanded(child: _buildField('start', 'Start Time')), const SizedBox(width: 10), Expanded(child: _buildField('end', 'End Time'))]),
            Row(children: [Expanded(child: _buildField('allocTime', 'Allocated Time')), const SizedBox(width: 10), Expanded(child: _buildField('deadline', 'Deadline'))]),
            _buildField('manager', 'Project Manager'),
            Row(children: [Expanded(child: _buildField('company', 'Company')), const SizedBox(width: 10), Expanded(child: _buildField('customer', 'Customer'))]),
            if (!isEdit) ...[
              const SizedBox(height: 20), const Text('Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)), const SizedBox(height: 10),
              ...reqs.asMap().entries.map((e) {
                int idx = e.key; var r = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                  child: Column(children: [
                    Row(children: [Expanded(flex: 2, child: TextField(controller: r['name'], decoration: const InputDecoration(labelText: 'Item Name'))), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState(() => reqs.removeAt(idx)))]),
                    Row(children: [Expanded(child: TextField(controller: r['cost'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost'))), const SizedBox(width: 10), DropdownButton<String>(value: r['status'], dropdownColor: Colors.grey[900], items: ['Needed', 'Available'].map((x) => DropdownMenuItem(value: x, child: Text(x, style: TextStyle(color: x == 'Available' ? Colors.greenAccent : Colors.orangeAccent)))).toList(), onChanged: (v) => setState(() => r['status'] = v!))]),
                  ]),
                );
              }),
              TextButton.icon(onPressed: () => setState(() => reqs.add({'name': TextEditingController(), 'cost': TextEditingController(), 'status': 'Needed'})), icon: const Icon(Icons.add, color: Colors.greenAccent), label: const Text('Add Requirement', style: TextStyle(color: Colors.greenAccent))),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isEdit ? Colors.purpleAccent : Colors.greenAccent, foregroundColor: Colors.black),
                onPressed: () async {
                  if (_ctrls['name']!.text.isEmpty) return;
                  final body = json.encode({
                    "name": _ctrls['name']!.text, "description": _ctrls['desc']!.text, "allocated_time": _ctrls['allocTime']!.text, "deadline": _ctrls['deadline']!.text, "start_time": _ctrls['start']!.text, "end_time": _ctrls['end']!.text, "project_manager": _ctrls['manager']!.text, "company": _ctrls['company']!.text, "customer": _ctrls['customer']!.text, "financial_cost": totalCost, "daily_hours_needed": double.parse(_ctrls['dailyHours']!.text.isEmpty ? "0" : _ctrls['dailyHours']!.text), "days_to_profit": 30,
                    if (!isEdit) "requirements": reqs.where((r) => r['name'].text.isNotEmpty).map((r) => {"name": r['name'].text, "is_available": r['status'] == 'Available', "cost": double.tryParse(r['cost'].text) ?? 0.0}).toList()
                  });
                  if (isEdit) await http.put(Uri.parse('https://rhind-backend.vercel.app/projects/${widget.existingProject!['id']}'), headers: {"Content-Type": "application/json"}, body: body);
                  else await http.post(Uri.parse('https://rhind-backend.vercel.app/projects/'), headers: {"Content-Type": "application/json"}, body: body);
                  Navigator.pop(context, true);
                },
                child: Text(isEdit ? 'Save Changes' : 'Save Project', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== 3. Project Workspace ==================
class ProjectWorkspaceScreen extends StatefulWidget {
  final Map project;
  const ProjectWorkspaceScreen({super.key, required this.project});
  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  List tasks = []; bool isLoading = true;
  late Map currentProject;
  
  @override void initState() { super.initState(); currentProject = widget.project; fetchProjectTasks(); }

  Future<void> fetchProjectTasks() async {
    try {
      final response = await http.get(Uri.parse('https://rhind-backend.vercel.app/tasks/project/${currentProject['id']}'));
      if (response.statusCode == 200) setState(() { tasks = json.decode(utf8.decode(response.bodyBytes)); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentProject['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProjectScreen(existingProject: currentProject))).then((res) {
              if (res == true) Navigator.pop(context); 
            }),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blueAccent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Desc: ${currentProject['description']}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text('Manager: ${currentProject['project_manager']} | Client: ${currentProject['customer']}'),
                    Text('Timeline: ${currentProject['start_time']} to ${currentProject['end_time']} (Deadline: ${currentProject['deadline']})', style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Project Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (isLoading) const CircularProgressIndicator()
            else if (tasks.isEmpty) const Text('No tasks added to this project yet.', style: TextStyle(color: Colors.white54))
            else ...tasks.map((t) => Card(
              child: ListTile(
                leading: Icon(t['is_completed'] ? Icons.check_circle : Icons.circle_outlined, color: t['is_completed'] ? Colors.greenAccent : Colors.white54),
                title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Assignee: ${t['assignees']} | Repeat: ${t['recurrence']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskWorkspaceScreen(task: t))).then((_) => fetchProjectTasks()),
              ),
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(projectId: currentProject['id']))).then((_) => fetchProjectTasks()),
        icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ================== 4. Task Workspace (Timer + Subtasks) ==================
class TaskWorkspaceScreen extends StatefulWidget {
  final Map task;
  const TaskWorkspaceScreen({super.key, required this.task});
  @override
  State<TaskWorkspaceScreen> createState() => _TaskWorkspaceScreenState();
}

class _TaskWorkspaceScreenState extends State<TaskWorkspaceScreen> {
  List subtasks = []; bool isLoading = true;
  Stopwatch _stopwatch = Stopwatch(); Timer? _timer; DateTime? _startTime;

  @override void initState() { super.initState(); fetchSubtasks(); }

  Future<void> fetchSubtasks() async {
    try {
      final response = await http.get(Uri.parse('https://rhind-backend.vercel.app/tasks/subtasks/${widget.task['id']}'));
      if (response.statusCode == 200) setState(() { subtasks = json.decode(utf8.decode(response.bodyBytes)); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  void _startWork() { if (_startTime == null) _startTime = DateTime.now(); _stopwatch.start(); _timer = Timer.periodic(const Duration(seconds: 1), (timer) => setState(() {})); }
  void _pauseWork() { _stopwatch.stop(); _timer?.cancel(); setState(() {}); }
  void _endWorkShift() {
    _pauseWork(); if (_stopwatch.elapsed.inSeconds == 0) return;
    final TextEditingController actualController = TextEditingController();
    double exactHours = _stopwatch.elapsed.inSeconds / 3600.0;
    String endT = DateTime.now().toIso8601String().substring(11, 16); String startT = _startTime!.toIso8601String().substring(11, 16);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), title: Text('End Shift: ${widget.task['title']}', style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [ Text('Duration: ${_stopwatch.elapsed.inHours}h ${_stopwatch.elapsed.inMinutes % 60}m', style: const TextStyle(color: Colors.greenAccent, fontSize: 18)), TextField(controller: actualController, decoration: const InputDecoration(labelText: 'Income Generated (EGP)'), keyboardType: TextInputType.number) ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _startWork(); }, child: const Text('Cancel & Resume')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              if (actualController.text.isEmpty) return;
              await http.post(Uri.parse('https://rhind-backend.vercel.app/daily_records/'), headers: {"Content-Type": "application/json"}, body: json.encode({"date": DateTime.now().toIso8601String().substring(0, 10), "start_time": startT, "end_time": endT, "actual_income": double.parse(actualController.text), "expected_income": 0.0, "hours_worked": double.parse(exactHours.toStringAsFixed(4)), "source": widget.task['title']}));
              setState(() { _stopwatch.reset(); _startTime = null; }); Navigator.pop(context);
            }, child: const Text('Save Shift', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = "${_stopwatch.elapsed.inHours.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}";
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task['title']), 
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(existingTask: widget.task))).then((res) { if (res == true) Navigator.pop(context); })),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () async { await http.delete(Uri.parse('https://rhind-backend.vercel.app/tasks/${widget.task['id']}')); Navigator.pop(context); }),
          IconButton(icon: const Icon(Icons.check, color: Colors.greenAccent), onPressed: () async { await http.put(Uri.parse('https://rhind-backend.vercel.app/tasks/${widget.task['id']}/toggle')); Navigator.pop(context); })
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(formattedTime, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.greenAccent)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_stopwatch.isRunning) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent), onPressed: _startWork, icon: const Icon(Icons.play_arrow, color: Colors.black), label: Text(_stopwatch.elapsed.inSeconds > 0 ? 'Resume' : 'Start', style: const TextStyle(color: Colors.black)))
                        else ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent), onPressed: _pauseWork, icon: const Icon(Icons.pause, color: Colors.black), label: const Text('Pause', style: TextStyle(color: Colors.black))),
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: _stopwatch.elapsed.inSeconds > 0 ? _endWorkShift : null, icon: const Icon(Icons.stop, color: Colors.white), label: const Text('End', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text('Desc: ${widget.task['description']}', style: const TextStyle(color: Colors.white70)),
            Text('Assignee: ${widget.task['assignees']} | Repeat: ${widget.task['recurrence']}'),
            const SizedBox(height: 20),
            const Text('Subtasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            const SizedBox(height: 10),
            if (isLoading) const CircularProgressIndicator()
            else if (subtasks.isEmpty) const Text('No subtasks.', style: TextStyle(color: Colors.white54))
            else ...subtasks.map((t) => Card(
              child: ListTile(
                leading: Icon(t['is_completed'] ? Icons.check_circle : Icons.account_tree_outlined, color: t['is_completed'] ? Colors.greenAccent : Colors.orangeAccent),
                title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskWorkspaceScreen(task: t))).then((_) => fetchSubtasks()),
              ),
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(projectId: widget.task['project_id'], parentId: widget.task['id']))).then((_) => fetchSubtasks()),
        icon: const Icon(Icons.add, color: Colors.black), label: const Text('Add Subtask', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}

// ================== 5. Add/Edit Task Screen ==================
class AddTaskScreen extends StatefulWidget {
  final int? projectId;
  final int? parentId;
  final Map? existingTask; 
  const AddTaskScreen({super.key, this.projectId, this.parentId, this.existingTask});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final Map<String, TextEditingController> _ctrls = {
    'title': TextEditingController(), 'desc': TextEditingController(), 'assignees': TextEditingController(), 'customer': TextEditingController(), 'deadline': TextEditingController(), 'allocTime': TextEditingController(), 'start': TextEditingController(), 'end': TextEditingController()
  };
  
  String _recurrence = 'None';
  final List<String> _recurrenceOptions = ['None', 'Daily', 'Custom'];
  List<String> _customDays = [];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _ctrls['title']!.text = widget.existingTask!['title'] ?? '';
      _ctrls['desc']!.text = widget.existingTask!['description'] ?? '';
      _ctrls['assignees']!.text = widget.existingTask!['assignees'] ?? '';
      _ctrls['customer']!.text = widget.existingTask!['customer'] ?? '';
      _ctrls['deadline']!.text = widget.existingTask!['deadline'] ?? '';
      _ctrls['allocTime']!.text = widget.existingTask!['allocated_time'] ?? '';
      _ctrls['start']!.text = widget.existingTask!['start_time'] ?? '';
      _ctrls['end']!.text = widget.existingTask!['end_time'] ?? '';
      
      String rec = widget.existingTask!['recurrence'] ?? 'None';
      if (rec == 'None' || rec == 'Daily') {
        _recurrence = rec;
      } else {
        _recurrence = 'Custom';
        _customDays = rec.split(',');
      }
    }
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    DateTime? date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date != null) {
      TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) setState(() => controller.text = "${date.toIso8601String().substring(0,10)} | ${time.format(context)}");
    }
  }

  Widget _buildField(String key, String label, {int lines = 1, bool isDateTime = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _ctrls[key], maxLines: lines, readOnly: isDateTime,
        onTap: isDateTime ? () => _pickDateTime(_ctrls[key]!) : null,
        decoration: InputDecoration(labelText: label, suffixIcon: isDateTime ? const Icon(Icons.calendar_month, color: Colors.greenAccent) : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.existingTask != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Task' : (widget.parentId == null ? 'New Task' : 'New Subtask'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('title', 'Task Title *'),
            _buildField('desc', 'Description', lines: 3),
            
            DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[900], value: _recurrence, decoration: const InputDecoration(labelText: 'Repeat'),
              items: _recurrenceOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            if (_recurrence == 'Custom') ...[
              const SizedBox(height: 10),
              const Text('Select Days:', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 5,
                children: _weekDays.map((day) => FilterChip(
                  label: Text(day),
                  selectedColor: Colors.greenAccent.withOpacity(0.3),
                  selected: _customDays.contains(day),
                  onSelected: (val) {
                    setState(() {
                      if (val) _customDays.add(day); else _customDays.remove(day);
                    });
                  },
                )).toList(),
              )
            ],
            const SizedBox(height: 15),

            Row(children: [Expanded(child: _buildField('start', 'Start Date & Time', isDateTime: true)), const SizedBox(width: 10), Expanded(child: _buildField('end', 'End Date & Time', isDateTime: true))]),
            Row(children: [Expanded(child: _buildField('deadline', 'Deadline', isDateTime: true)), const SizedBox(width: 10), Expanded(child: _buildField('allocTime', 'Allocated Time'))]),
            _buildField('assignees', 'Assignees'),
            _buildField('customer', 'Customer'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isEdit ? Colors.purpleAccent : (widget.parentId == null ? Colors.blueAccent : Colors.orangeAccent)),
                onPressed: () async {
                  if (_ctrls['title']!.text.isEmpty) return;
                  String finalRecurrence = _recurrence == 'Custom' ? _customDays.join(',') : _recurrence;
                  if (finalRecurrence.isEmpty) finalRecurrence = 'None';

                  final body = json.encode({
                    "title": _ctrls['title']!.text, "description": _ctrls['desc']!.text, "assignees": _ctrls['assignees']!.text, "customer": _ctrls['customer']!.text, "deadline": _ctrls['deadline']!.text, "allocated_time": _ctrls['allocTime']!.text, "start_time": _ctrls['start']!.text, "end_time": _ctrls['end']!.text, "recurrence": finalRecurrence,
                    if (!isEdit) "project_id": widget.projectId, if (!isEdit) "parent_id": widget.parentId
                  });
                  if (isEdit) await http.put(Uri.parse('https://rhind-backend.vercel.app/tasks/${widget.existingTask!['id']}'), headers: {"Content-Type": "application/json"}, body: body);
                  else await http.post(Uri.parse('https://rhind-backend.vercel.app/tasks/'), headers: {"Content-Type": "application/json"}, body: body);
                  Navigator.pop(context, true); 
                },
                child: Text(isEdit ? 'Save Changes' : 'Create Task', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== 6. Wallet Screen ==================
class WalletScreen extends StatefulWidget { const WalletScreen({super.key}); @override State<WalletScreen> createState() => _WalletScreenState(); }
class _WalletScreenState extends State<WalletScreen> {
  List transactions = []; bool isLoading = true;
  @override void initState() { super.initState(); fetchTransactions(); }
  Future<void> fetchTransactions() async { try { final r = await http.get(Uri.parse('https://rhind-backend.vercel.app/transactions/')); if (r.statusCode == 200) setState(() { transactions = json.decode(utf8.decode(r.bodyBytes)); isLoading = false; }); } catch (e) { setState(() => isLoading = false); } }
  Future<void> deleteTrans(int id) async { await http.delete(Uri.parse('https://rhind-backend.vercel.app/transactions/$id')); fetchTransactions(); }
  void showAddOrEditDialog({Map? trans}) {
    final TextEditingController amountController = TextEditingController(text: trans != null ? trans['amount'].toString() : ''); final TextEditingController reasonController = TextEditingController(text: trans != null ? trans['reason'] : ''); final TextEditingController dateController = TextEditingController(text: trans != null ? trans['date'] : DateTime.now().toIso8601String().substring(0, 10)); String selectedType = trans != null ? trans['trans_type'] : 'Expense';
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setStateDialog) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: Text(trans == null ? 'New Transaction' : 'Edit Transaction', style: const TextStyle(color: Colors.white)), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(dropdownColor: Colors.grey[900], value: selectedType, decoration: const InputDecoration(labelText: 'Type'), items: ['Expense', 'Income'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: e == 'Income' ? Colors.greenAccent : Colors.redAccent)))).toList(), onChanged: (v) => setStateDialog(() => selectedType = v!)), TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number), TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')), TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () async { if (amountController.text.isEmpty || reasonController.text.isEmpty) return; final body = json.encode({"amount": double.parse(amountController.text), "trans_type": selectedType, "reason": reasonController.text, "date": dateController.text}); if (trans == null) await http.post(Uri.parse('https://rhind-backend.vercel.app/transactions/'), headers: {"Content-Type": "application/json"}, body: body); else await http.put(Uri.parse('https://rhind-backend.vercel.app/transactions/${trans['id']}'), headers: {"Content-Type": "application/json"}, body: body); Navigator.pop(context); setState(() => isLoading = true); fetchTransactions(); }, child: const Text('Save', style: TextStyle(color: Colors.white)))])));
  }
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Treasury & Transactions', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true), body: RefreshIndicator(onRefresh: fetchTransactions, color: Colors.greenAccent, backgroundColor: Colors.black, child: isLoading ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent)) : transactions.isEmpty ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.white54))) : ListView.builder(padding: const EdgeInsets.all(10), itemCount: transactions.length, itemBuilder: (context, index) { final t = transactions[index]; bool isIncome = t['trans_type'] == 'Income'; return Card(color: Colors.white10, child: ListTile(leading: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.greenAccent : Colors.redAccent), title: Text('${t['amount']} EGP - ${t['reason']}', style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.greenAccent : Colors.redAccent)), subtitle: Text(t['date'], style: const TextStyle(color: Colors.white54)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: () => showAddOrEditDialog(trans: t)), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => deleteTrans(t['id']))]))); })), floatingActionButton: FloatingActionButton.extended(backgroundColor: Colors.blueAccent, onPressed: () => showAddOrEditDialog(), icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Transaction', style: TextStyle(color: Colors.white)))); }
}

// ================== 7. Tasks & Targets Screen ==================
class TasksTargetsScreen extends StatelessWidget { const TasksTargetsScreen({super.key}); @override Widget build(BuildContext context) { return DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: const Text('Global Tasks & Targets'), centerTitle: true, bottom: const TabBar(indicatorColor: Colors.greenAccent, labelColor: Colors.greenAccent, unselectedLabelColor: Colors.white54, tabs: [Tab(icon: Icon(Icons.check_box), text: 'Tasks'), Tab(icon: Icon(Icons.track_changes), text: 'Targets')])), body: const TabBarView(children: [TasksTab(), TargetsTab()]))); } }

class TasksTab extends StatefulWidget { const TasksTab({super.key}); @override State<TasksTab> createState() => _TasksTabState(); }
class _TasksTabState extends State<TasksTab> {
  List tasks = []; bool isLoading = true;
  @override void initState() { super.initState(); fetchTasks(); }
  Future<void> fetchTasks() async { try { final r = await http.get(Uri.parse('https://rhind-backend.vercel.app/tasks/')); if (r.statusCode == 200) setState(() { tasks = json.decode(utf8.decode(r.bodyBytes)); isLoading = false; }); } catch (e) { setState(() => isLoading = false); } }
  Future<void> toggleTask(int id) async { await http.put(Uri.parse('https://rhind-backend.vercel.app/tasks/$id/toggle')); fetchTasks(); }
  Future<void> deleteTask(int id) async { await http.delete(Uri.parse('https://rhind-backend.vercel.app/tasks/$id')); fetchTasks(); }
  @override Widget build(BuildContext context) { return Scaffold(body: isLoading ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent)) : tasks.isEmpty ? const Center(child: Text('No personal tasks!')) : ListView.builder(itemCount: tasks.length, itemBuilder: (context, index) { final t = tasks[index]; return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ListTile(leading: Checkbox(value: t['is_completed'], activeColor: Colors.greenAccent, checkColor: Colors.black, onChanged: (val) => toggleTask(t['id'])), title: Text(t['title'], style: TextStyle(decoration: t['is_completed'] ? TextDecoration.lineThrough : null, color: t['is_completed'] ? Colors.white54 : Colors.white)), subtitle: Text(t['recurrence'] ?? 'None'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(existingTask: t))).then((_) => fetchTasks())), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => deleteTask(t['id']))]))); }), floatingActionButton: FloatingActionButton(backgroundColor: Colors.greenAccent, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen())).then((_) => fetchTasks()), child: const Icon(Icons.add, color: Colors.black))); }
}

class TargetsTab extends StatefulWidget { const TargetsTab({super.key}); @override State<TargetsTab> createState() => _TargetsTabState(); }
class _TargetsTabState extends State<TargetsTab> {
  Map targetData = {}; bool isLoading = true;
  @override void initState() { super.initState(); fetchTargets(); }
  Future<void> fetchTargets() async { setState(() => isLoading = true); try { final r = await http.get(Uri.parse('https://rhind-backend.vercel.app/targets/?period=month')); if (r.statusCode == 200) setState(() { targetData = json.decode(utf8.decode(r.bodyBytes)); isLoading = false; }); } catch (e) { setState(() => isLoading = false); } }
  Future<void> deleteTarget(int id) async { await http.delete(Uri.parse('https://rhind-backend.vercel.app/targets/$id')); fetchTargets(); }
  void showAddProgressDialog(int id) { final TextEditingController ac = TextEditingController(); showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text('Add Progress', style: TextStyle(color: Colors.white)), content: TextField(controller: ac, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Reached (EGP)')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () async { if (ac.text.isEmpty) return; await http.put(Uri.parse('https://rhind-backend.vercel.app/targets/$id/add'), headers: {"Content-Type": "application/json"}, body: json.encode({"amount": double.parse(ac.text)})); Navigator.pop(context); fetchTargets(); }, child: const Text('Save'))])); }
  void showAddTargetDialog() { final TextEditingController tc = TextEditingController(); final TextEditingController ac = TextEditingController(); showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text('New Target', style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: tc, decoration: const InputDecoration(labelText: 'Target Title')), TextField(controller: ac, decoration: const InputDecoration(labelText: 'Target Amount (EGP)'), keyboardType: TextInputType.number)]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent), onPressed: () async { if (tc.text.isEmpty || ac.text.isEmpty) return; await http.post(Uri.parse('https://rhind-backend.vercel.app/targets/'), headers: {"Content-Type": "application/json"}, body: json.encode({"title": tc.text, "target_amount": double.parse(ac.text)})); Navigator.pop(context); fetchTargets(); }, child: const Text('Save', style: TextStyle(color: Colors.black)))])); }
  @override Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    double st = targetData['smart_daily_target'] ?? 0.0, ti = targetData['today_actual_income'] ?? 0.0, sp = st > 0 ? (ti / st).clamp(0.0, 1.0) : 1.0; int dl = targetData['days_left'] ?? 0; List mt = targetData['manual_targets'] ?? [];
    return Scaffold(body: RefreshIndicator(onRefresh: fetchTargets, color: Colors.greenAccent, backgroundColor: Colors.black, child: ListView(padding: const EdgeInsets.all(10), children: [Card(color: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.orangeAccent)), child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_fire_department, color: Colors.orangeAccent), SizedBox(width: 10), Text('Daily Survival', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent))]), Text('$dl Days Left', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold))]), const SizedBox(height: 15), LinearProgressIndicator(value: sp, backgroundColor: Colors.white10, color: sp == 1.0 ? Colors.greenAccent : Colors.orangeAccent, minHeight: 12), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Done: $ti EGP', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)), Text('Target: $st EGP', style: const TextStyle(color: Colors.white))])]))), const SizedBox(height: 20), const Text('Personal Targets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), ...mt.map((t) { double p = (t['current_amount'] / t['target_amount']).clamp(0.0, 1.0); return Card(child: Padding(padding: const EdgeInsets.all(15.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => deleteTarget(t['id']))]), LinearProgressIndicator(value: p, backgroundColor: Colors.white24, color: p == 1.0 ? Colors.greenAccent : Colors.blueAccent, minHeight: 10), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${t['current_amount']} / ${t['target_amount']} EGP', style: const TextStyle(color: Colors.white70)), TextButton.icon(onPressed: () => showAddProgressDialog(t['id']), icon: const Icon(Icons.add, color: Colors.greenAccent), label: const Text('Add', style: TextStyle(color: Colors.greenAccent)))])]))); })])), floatingActionButton: FloatingActionButton(backgroundColor: Colors.greenAccent, onPressed: showAddTargetDialog, child: const Icon(Icons.flag, color: Colors.black)));
  }
}

// ================== 8. Creditors Screen ==================
class CreditorsScreen extends StatefulWidget { const CreditorsScreen({super.key}); @override State<CreditorsScreen> createState() => _CreditorsScreenState(); }
class _CreditorsScreenState extends State<CreditorsScreen> {
  List creditors = []; bool isLoading = true;
  @override void initState() { super.initState(); fetchCreditors(); }
  Future<void> fetchCreditors() async { try { final response = await http.get(Uri.parse('https://rhind-backend.vercel.app/creditors/list')); if (response.statusCode == 200) setState(() { creditors = json.decode(utf8.decode(response.bodyBytes)); isLoading = false; }); } catch (e) { setState(() => isLoading = false); } }
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Debts & Creditors'), centerTitle: true), body: isLoading ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent)) : ListView.builder(itemCount: creditors.length, itemBuilder: (context, index) { final c = creditors[index]; return Card(child: ListTile(leading: const Icon(Icons.person), title: Text(c['name']), subtitle: Text(c['phone']))); }), floatingActionButton: FloatingActionButton(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, onPressed: () {}, child: const Icon(Icons.add))); }
}