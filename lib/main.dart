import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

// ⚠️ EDIT THESE VARIABLES WITH YOUR GOOGLE FORM SECRETS FROM STEP 1
const String googleFormBaseUrl = 'https://docs.google.com/forms/d/e/1FAIpQLScU_wh6vn0MmTkVP8Jakc-CTgwR-GEzjY73M3pHxutgJ5Vd0w/formResponse';
const String emojiFieldId = 'entry.1044774377'; 
const String activityFieldId = 'entry.85606868';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _activityController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  String selectedEmoji = '';
  bool isSubmitting = false;

  final List<String> emojis = ['😊', '🥰', '🥳', '😎', '🤔', '🥱', '😴', '😢', '🥵', '😡'];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  // Set up local background reminders
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    await _notificationsPlugin.initialize(initializationSettings);
    
    // Request permission explicitly for modern Android devices
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _scheduleHourlyReminders();
  }

  Future<void> _scheduleHourlyReminders() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hourly_reminder_id',
      'Hourly Reminders',
      channelDescription: 'Reminds you to log how you are doing',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    // Schedule reminders across daytime hours (9 AM to 10 PM)
    for (int hour = 9; hour <= 22; hour++) {
      await _notificationsPlugin.zonedSchedule(
        hour,
        'Hey love! ❤️',
        'How are you doing right now? Let me know!',
        _nextInstanceOfHour(hour),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfHour(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Network submission directly to your Google Sheet via the Form engine
  Future<void> _submitData() async {
    if (selectedEmoji.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emoji first! 😘')),
      );
      return;
    }

    setState(() { isSubmitting = true; });

    try {
      await http.post(
        Uri.parse(googleFormBaseUrl),
        body: {
          emojiFieldId: selectedEmoji,
          activityFieldId: _activityController.text,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted! Have a wonderful hour! ✨❤️')),
      );
      
      setState(() {
        selectedEmoji = '';
        _activityController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data. Check connection!')),
      );
    } finally {
      setState(() { isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hey Beautiful ✨', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling right now?', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final emoji = emojis[index];
                final isSelected = selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => selectedEmoji = emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('What are you up to?', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _activityController,
              decoration: InputDecoration(
                hintText: 'Studying, eating, hanging out...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Status ❤️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
