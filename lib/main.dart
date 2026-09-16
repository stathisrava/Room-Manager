import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

/* ===================== MODELS ===================== */

class Floor {
  String id;
  String name;
  List<Room> rooms;
  int gridWidth;
  int gridHeight;

  Floor({
    required this.id,
    required this.name,
    List<Room>? rooms,
    this.gridWidth = 15,
    this.gridHeight = 10,
  }) : rooms = rooms ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gridWidth': gridWidth,
    'gridHeight': gridHeight,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  factory Floor.fromJson(Map<String, dynamic> json) => Floor(
    id: json['id'] as String,
    name: json['name'] as String,
    gridWidth: json['gridWidth'] as int? ?? 15,
    gridHeight: json['gridHeight'] as int? ?? 10,
    rooms: (json['rooms'] as List<dynamic>)
        .map((r) => Room.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

class Room {
  String id;
  int x;
  int y;

  String roomName;
  String firstName;
  String lastName;
  String checkIn;
  String checkOut;
  String comments;
  RoomStatus status;

  Room({
    required this.id,
    required this.x,
    required this.y,
    this.roomName = "",
    this.firstName = "",
    this.lastName = "",
    this.checkIn = "",
    this.checkOut = "",
    this.comments = "",
    this.status = RoomStatus.available,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'roomName': roomName,
    'firstName': firstName,
    'lastName': lastName,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'comments': comments,
    'status': status.name,
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    x: json['x'] as int,
    y: json['y'] as int,
    roomName: json['roomName'] as String? ?? "",
    firstName: json['firstName'] as String? ?? "",
    lastName: json['lastName'] as String? ?? "",
    checkIn: json['checkIn'] as String? ?? "",
    checkOut: json['checkOut'] as String? ?? "",
    comments: json['comments'] as String? ?? "",
    status: RoomStatus.values.firstWhere(
          (e) => e.name == json['status'],
      orElse: () => RoomStatus.available,
    ),
  );
}

// "extraRoom" is a 4th, separate availability option (not a normal
// guest room) used for storage / utility squares on the grid.
enum RoomStatus { available, taken, damage, extraRoom }

extension RoomStatusLabel on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available:
        return "Available";
      case RoomStatus.taken:
        return "Taken";
      case RoomStatus.damage:
        return "Damage";
      case RoomStatus.extraRoom:
        return "Extra Room";
    }
  }

  bool get isExtra => this == RoomStatus.extraRoom;
}

/* ===================== DATE HELPERS ===================== */

String formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return "$dd/$mm/${d.year}";
}

DateTime? tryParseDate(String s) {
  final parts = s.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

String daysAwayLabel(DateTime today, DateTime date) {
  final diff = date.difference(today).inDays;
  if (diff <= 0) return "Today";
  if (diff == 1) return "Tomorrow";
  return "In $diff days";
}

class UpcomingCheckout {
  final Floor floor;
  final Room room;
  final DateTime date;

  UpcomingCheckout({required this.floor, required this.room, required this.date});
}

/* ===================== APP ===================== */

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Floor> floors = [];
  Floor? currentFloor;
  bool isLoading = true;

  // Grid dimensions now live per-floor (see Floor.gridWidth/gridHeight).
  // These are just sane bounds for the "custom grid size" input.
  static const int minGridDim = 1;
  static const int maxGridDim = 40;

  // Fixed cell size in logical pixels; the grid scrolls both ways as needed.
  static const double cellSize = 56;

  static const String _storageKey = 'hotel_floor_planner_data';

  // Used so dialogs always get a context that is *below* MaterialApp
  // (i.e. one that has access to MaterialLocalizations).
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  BuildContext get dialogContext => navigatorKey.currentContext!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ===================== PERSISTENCE ===================== */

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        floors.clear();
        floors.addAll(
          decoded.map((f) => Floor.fromJson(f as Map<String, dynamic>)),
        );
      } catch (_) {
        // Ignore corrupt data, start fresh.
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(floors.map((f) => f.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Wraps setState so every state change is immediately persisted.
  void _update(VoidCallback fn) {
    setState(fn);
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Room Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (currentFloor == null ? buildFloorList() : buildFloorView()),
    );
  }

  /* ===================== FLOOR LIST ===================== */

  List<UpcomingCheckout> _getUpcomingCheckouts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = <UpcomingCheckout>[];
    for (final floor in floors) {
      for (final room in floor.rooms) {
        if (room.status.isExtra) continue;
        final parsed = tryParseDate(room.checkOut);
        if (parsed == null) continue;
        final date = DateTime(parsed.year, parsed.month, parsed.day);
        if (date.isBefore(today)) continue;
        result.add(UpcomingCheckout(floor: floor, room: room, date: date));
      }
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Widget buildFloorList() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      appBar: AppBar(
        title: const Text("Floors"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation:  2,
        actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 20,          // increase to 20 if you want it bigger
                //fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: showAddFloorDialog,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: const Text(
              "New Floor",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
      ),
//    ), // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: showAddFloorDialog,
      //   icon: const Icon(Icons.add),
      //   label: const Text("New Floor"),
      //   backgroundColor: Colors.green,
      // ),
      body: Column(
        children: [
          Expanded(
            child: floors.isEmpty
                ? const Center(
              child: Text(
                "No floors yet.\nTap + to create one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: floors.length,
              itemBuilder: (context, index) {
                final floor = floors[index];

                final available = floor.rooms
                    .where((r) => r.status == RoomStatus.available)
                    .length;
                final taken = floor.rooms
                    .where((r) => r.status == RoomStatus.taken)
                    .length;
                final damage = floor.rooms
                    .where((r) => r.status == RoomStatus.damage)
                    .length;
                final extra = floor.rooms
                    .where((r) => r.status == RoomStatus.extraRoom)
                    .length;

                return Card(
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.12),
                      child: const Icon(Icons.layers, color: Colors.green),
                    ),
                    title: Text(
                      floor.name,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _statusChip("${floor.rooms.length} total", Colors.teal),
                          _statusChip("$available available", Colors.green),
                          _statusChip("$taken taken", Colors.red),
                          _statusChip("$damage damage", Colors.orange),
                          _statusChip("$extra extra", Colors.blueGrey),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => confirmDeleteFloor(floor),
                    ),
                    onTap: () {
                      setState(() {
                        currentFloor = floor;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _buildUpcomingCheckoutsSection(),
        ],
      ),
    );
  }

  Widget _buildUpcomingCheckoutsSection() {
    final checkouts = _getUpcomingCheckouts();
    final today = DateTime.now();
    final todayLabel = formatDate(DateTime(today.year, today.month, today.day));

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.green.withOpacity(0.2), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Upcoming Check-outs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  "Today: $todayLabel",
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (checkouts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                "No upcoming check-outs.",
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: checkouts.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final c = checkouts[index];
                  final today0 = DateTime(today.year, today.month, today.day);
                  final label = daysAwayLabel(today0, c.date);
                  final isToday = label == "Today";

                  final lastName = c.room.lastName.trim().isEmpty
                      ? "(no name)"
                      : c.room.lastName.trim();

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.redAccent : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      lastName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      "Check-out: ${formatDate(c.date)} · ${c.room.roomName.isEmpty ? 'Room' : c.room.roomName} · ${c.floor.name}",
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isToday ? Colors.redAccent : Colors.green).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.redAccent : Colors.green.shade700,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        currentFloor = c.floor;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  void showAddFloorDialog() {
    final TextEditingController controller = TextEditingController();
    final widthController = TextEditingController(text: "15");
    final heightController = TextEditingController(text: "10");
    String? errorText;

    showDialog(
      context: dialogContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Create New Floor"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Floor Name",
                        hintText: "e.g. Floor 1",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Width (squares)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Height (squares)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    final width = int.tryParse(widthController.text.trim());
                    final height = int.tryParse(heightController.text.trim());

                    if (name.isEmpty) {
                      setDialogState(() => errorText = "Enter a floor name.");
                      return;
                    }
                    if (width == null ||
                        height == null ||
                        width < minGridDim ||
                        height < minGridDim ||
                        width > maxGridDim ||
                        height > maxGridDim) {
                      setDialogState(() {
                        errorText =
                        "Width and height must be between $minGridDim and $maxGridDim.";
                      });
                      return;
                    }

                    _update(() {
                      floors.add(
                        Floor(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          gridWidth: width,
                          gridHeight: height,
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showEditFloorDialog(Floor floor) {
    final controller = TextEditingController(text: floor.name);
    final widthController = TextEditingController(text: floor.gridWidth.toString());
    final heightController = TextEditingController(text: floor.gridHeight.toString());
    String? errorText;

    showDialog(
      context: dialogContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Floor"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Floor Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Width (squares)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Height (squares)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    final width = int.tryParse(widthController.text.trim());
                    final height = int.tryParse(heightController.text.trim());

                    if (name.isEmpty) {
                      setDialogState(() => errorText = "Enter a floor name.");
                      return;
                    }
                    if (width == null ||
                        height == null ||
                        width < minGridDim ||
                        height < minGridDim ||
                        width > maxGridDim ||
                        height > maxGridDim) {
                      setDialogState(() {
                        errorText =
                        "Width and height must be between $minGridDim and $maxGridDim.";
                      });
                      return;
                    }

                    final outOfBounds = floor.rooms.where(
                          (r) => r.x >= width || r.y >= height,
                    );
                    if (outOfBounds.isNotEmpty) {
                      setDialogState(() {
                        errorText =
                        "Can't shrink: ${outOfBounds.length} room(s) would fall outside the new grid. Move or delete them first.";
                      });
                      return;
                    }

                    _update(() {
                      floor.name = name;
                      floor.gridWidth = width;
                      floor.gridHeight = height;
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmDeleteFloor(Floor floor) {
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Floor"),
        content: Text('Delete "${floor.name}" and all its rooms?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _update(() {
                floors.remove(floor);
                if (currentFloor?.id == floor.id) currentFloor = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /* ===================== EXCEL EXPORT ===================== */

  Future<void> exportFloorToExcel(Floor floor) async {
    try {
      final workbook = xls.Excel.createExcel();
      const sheetName = 'Rooms';
      workbook.rename(workbook.getDefaultSheet()!, sheetName);
      final sheet = workbook[sheetName];

      sheet.appendRow([xls.TextCellValue('Floor: ${floor.name}')]);
      sheet.appendRow([xls.TextCellValue('')]);
      sheet.appendRow([
        xls.TextCellValue('Room Name'),
        xls.TextCellValue('Position'),
        xls.TextCellValue('First Name'),
        xls.TextCellValue('Last Name'),
        xls.TextCellValue('Check In'),
        xls.TextCellValue('Check Out'),
        xls.TextCellValue('Status'),
        xls.TextCellValue('Comments'),
      ]);

      final sortedRooms = [...floor.rooms]
        ..sort((a, b) {
          final byY = a.y.compareTo(b.y);
          return byY != 0 ? byY : a.x.compareTo(b.x);
        });

      for (final r in sortedRooms) {
        final isExtra = r.status.isExtra;
        sheet.appendRow([
          xls.TextCellValue(r.roomName.isEmpty ? '-' : r.roomName),
          xls.TextCellValue('X${r.x}, Y${r.y}'),
          xls.TextCellValue(isExtra ? '' : r.firstName),
          xls.TextCellValue(isExtra ? '' : r.lastName),
          xls.TextCellValue(isExtra ? '' : r.checkIn),
          xls.TextCellValue(isExtra ? '' : r.checkOut),
          xls.TextCellValue(r.status.label),
          xls.TextCellValue(r.comments),
        ]);
      }

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Could not encode spreadsheet.');

      final dir = await getTemporaryDirectory();
      final safeName = floor.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${dir.path}/${safeName}_rooms.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Room export for ${floor.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  /* ===================== FLOOR GRID ===================== */

  Widget buildFloorView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      appBar: AppBar(
        title: Text(currentFloor!.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              currentFloor = null;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Floor",
            onPressed: () => showEditFloorDialog(currentFloor!),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: "Export to Excel",
            onPressed: () => exportFloorToExcel(currentFloor!),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLegend(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: currentFloor!.gridWidth * cellSize,
                        height: currentFloor!.gridHeight * cellSize,
                        child: Column(
                          children: List.generate(currentFloor!.gridHeight, (y) {
                            return Row(
                              children: List.generate(currentFloor!.gridWidth, (x) {
                                return SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: buildCell(x, y),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      color: Colors.green.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _legendDot(Colors.greenAccent, "Available"),
          _legendDot(Colors.redAccent, "Taken"),
          _legendDot(Colors.orangeAccent, "Damage"),
          _legendDot(Colors.blueGrey.shade300, "Extra Room"),
          const SizedBox(
            width: double.infinity,
            child: Text(
              "Tap a square to edit. Press and hold to drag a room anywhere on the grid.",
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget buildCell(int x, int y) {
    Room? room = findRoom(x, y);

    return DragTarget<Room>(
      onWillAcceptWithDetails: (details) => canMove(details.data, x, y),
      onAcceptWithDetails: (details) {
        moveRoom(details.data, x, y);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isValidTarget = candidateData.isNotEmpty;

        final cell = Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: room == null
                ? null
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                getColor(room.status),
                getColor(room.status).withOpacity(0.7),
              ],
            ),
            color: room == null
                ? (isValidTarget ? Colors.green[100] : Colors.grey[100])
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isValidTarget
                  ? Colors.green
                  : (room == null ? Colors.black12 : Colors.black26),
              width: isValidTarget ? 2.5 : 1,
            ),
            boxShadow: room == null
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: room == null
              ? Icon(Icons.add, size: 16, color: Colors.grey[400])
              : roomBox(room),
        );

        if (room == null) {
          return GestureDetector(
            onTap: () => showRoomDialog(x, y, null),
            child: cell,
          );
        }

        return GestureDetector(
          onTap: () => showRoomDialog(x, y, room),
          child: LongPressDraggable<Room>(
            data: room,
            delay: const Duration(milliseconds: 350),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cellSize,
                height: cellSize,
                child: Transform.scale(scale: 1.08, child: cell),
              ),
            ),
            childWhenDragging: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: cell,
          ),
        );
      },
    );
  }

  /* ===================== ROOM LOGIC ===================== */

  Room? findRoom(int x, int y) {
    for (final r in currentFloor!.rooms) {
      if (r.x == x && r.y == y) return r;
    }
    return null;
  }

  void moveRoom(Room room, int newX, int newY) {
    if (!canMove(room, newX, newY)) return;
    _update(() {
      room.x = newX;
      room.y = newY;
    });
  }

  bool canMove(Room room, int x, int y) {
    if (x < 0 || x >= currentFloor!.gridWidth || y < 0 || y >= currentFloor!.gridHeight) {
      return false;
    }
    if (room.x == x && room.y == y) return false;

    // prevent overlap onto another room
    return !currentFloor!.rooms.any((r) => r != room && r.x == x && r.y == y);
  }

  /* ===================== ROOM UI ===================== */

  Widget roomBox(Room room) {
    final isExtra = room.status.isExtra;
    final roomNameLabel = room.roomName.isEmpty
        ? (isExtra ? "Extra" : "Room")
        : room.roomName;
    final guestLabel = "${room.firstName} ${room.lastName}".trim();
    final showGuestLabel = !isExtra && guestLabel.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roomNameLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (showGuestLabel)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  guestLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color getColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.greenAccent;
      case RoomStatus.taken:
        return Colors.redAccent;
      case RoomStatus.damage:
        return Colors.orangeAccent;
      case RoomStatus.extraRoom:
        return Colors.blueGrey.shade300;
    }
  }

  /* ===================== ROOM CREATE / EDIT ===================== */

  void showRoomDialog(int x, int y, Room? existingRoom) {
    final isNew = existingRoom == null;

    final roomName = TextEditingController(text: existingRoom?.roomName ?? "");
    final first = TextEditingController(text: existingRoom?.firstName ?? "");
    final last = TextEditingController(text: existingRoom?.lastName ?? "");
    final checkIn = TextEditingController(text: existingRoom?.checkIn ?? "");
    final checkOut = TextEditingController(text: existingRoom?.checkOut ?? "");
    final comments = TextEditingController(text: existingRoom?.comments ?? "");

    RoomStatus status = existingRoom?.status ?? RoomStatus.available;

    showDialog(
      context: dialogContext,
      builder: (outerCtx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate(TextEditingController controller) async {
              final initial = tryParseDate(controller.text) ?? DateTime.now();
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: initial,
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 3),
              );
              if (picked != null) {
                setDialogState(() {
                  controller.text = formatDate(picked);
                });
              }
            }

            final isExtra = status.isExtra;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isNew
                  ? (isExtra ? "New Extra Room" : "New Room")
                  : (isExtra ? "Extra Room" : "Room Info")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: roomName,
                      decoration: const InputDecoration(
                        labelText: "Room Name",
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    if (!isExtra) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: first,
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: last,
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: checkIn,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Check In",
                          prefixIcon: Icon(Icons.login),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => pickDate(checkIn),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: checkOut,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Check Out",
                          prefixIcon: Icon(Icons.logout),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => pickDate(checkOut),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: comments,
                      decoration: const InputDecoration(
                        labelText: "Comments",
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<RoomStatus>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: "Availability",
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: RoomStatus.values.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e.label),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => status = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      _update(() {
                        currentFloor!.rooms.remove(existingRoom);
                      });
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Delete"),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final saveIsExtra = status.isExtra;
                    _update(() {
                      if (isNew) {
                        currentFloor!.rooms.add(
                          Room(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            x: x,
                            y: y,
                            roomName: roomName.text,
                            firstName: saveIsExtra ? "" : first.text,
                            lastName: saveIsExtra ? "" : last.text,
                            checkIn: saveIsExtra ? "" : checkIn.text,
                            checkOut: saveIsExtra ? "" : checkOut.text,
                            comments: comments.text,
                            status: status,
                          ),
                        );
                      } else {
                        existingRoom.roomName = roomName.text;
                        existingRoom.firstName = saveIsExtra ? "" : first.text;
                        existingRoom.lastName = saveIsExtra ? "" : last.text;
                        existingRoom.checkIn = saveIsExtra ? "" : checkIn.text;
                        existingRoom.checkOut = saveIsExtra ? "" : checkOut.text;
                        existingRoom.comments = comments.text;
                        existingRoom.status = status;
                      }
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}