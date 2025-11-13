import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp();
  print('🔔 [BG] Message data: ${message.data}');
  print(
    '🔔 [BG] Notification: ${message.notification?.title} - ${message.notification?.body}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MessagingApp());
}

class MessagingApp extends StatelessWidget {
  const MessagingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICA 17 – FCM Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MessagingHomePage(),
    );
  }
}

class MessagingHomePage extends StatefulWidget {
  const MessagingHomePage({super.key});

  @override
  State<MessagingHomePage> createState() => _MessagingHomePageState();
}

class _MessagingHomePageState extends State<MessagingHomePage> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _fcmToken;
  bool _permissionGranted = false;
  final List<_ReceivedNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    // 1. Request notification permission (Android 13+, iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    setState(() {
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    });

    print('🔧 Notification permission: ${settings.authorizationStatus}');

    // 2. Get FCM token
    final token = await _messaging.getToken();
    setState(() {
      _fcmToken = token;
    });
    print('✅ FCM Token: $token');

    // Optional: subscribe to a topic (for testing)
    await _messaging.subscribeToTopic('messaging');
    print('📌 Subscribed to topic "messaging"');

    // 3. Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 [FG] Message received');
      _handleMessage(message, source: 'Foreground');
    });

    // 4. When user taps a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 [CLICK] Notification opened app');
      _handleMessage(message, source: 'onMessageOpenedApp');
    });

    // 5. If the app was launched from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('📲 [INITIAL] App opened from terminated via notification');
      _handleMessage(initialMessage, source: 'InitialMessage');
    }
  }

  void _handleMessage(RemoteMessage message, {required String source}) {
    final String title = message.notification?.title ?? 'No title';
    final String body = message.notification?.body ?? 'No body';

    // We will use custom data key: "type" = "important" or "regular"
    final String type = (message.data['type'] ?? 'regular')
        .toString()
        .toLowerCase();
    final bool isImportant = type == 'important';

    print('🔍 [$source] type: $type | important: $isImportant');
    print('🔍 data: ${message.data}');

    final received = _ReceivedNotification(
      title: title,
      body: body,
      isImportant: isImportant,
      source: source,
      receivedAt: DateTime.now(),
    );

    setState(() {
      _notifications.insert(0, received); // newest at top
    });

    // Show simple dialog when message comes in foreground
    if (source == 'Foreground') {
      _showNotificationDialog(received);
    }
  }

  void _showNotificationDialog(_ReceivedNotification n) {
    final Color bg = n.isImportant ? Colors.red.shade100 : Colors.blue.shade50;
    final String label = n.isImportant ? 'IMPORTANT' : 'REGULAR';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bg,
          title: Text(
            'New $label Notification',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: n.isImportant ? Colors.red.shade800 : Colors.blue.shade800,
            ),
          ),
          content: Text(n.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Cloud Messaging – ICA 17')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Token
            Text(
              '1. Your FCM Token',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!_permissionGranted)
              const Text(
                'Notification permission not granted.\n'
                'Allow notifications in system settings for full functionality.',
              )
            else
              SelectableText(
                _fcmToken ?? 'Fetching token...',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            const Text(
              'Use this token in Firebase Console → Cloud Messaging → "Send test message".',
              style: TextStyle(fontSize: 12),
            ),
            const Divider(height: 32),

            // Section 2: Instructions
            Text(
              '2. Notification Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '- REGULAR: no special data (or type = regular)\n'
              '- IMPORTANT: data key "type" = "important"\n'
              'Important notifications will be highlighted in red.',
            ),
            const SizedBox(height: 16),

            // Section 3: List of notifications
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications yet.\n'
                        'Send one from Firebase Console to see it here.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final Color cardColor = n.isImportant
                            ? Colors.red.shade100
                            : Colors.grey.shade200;
                        final Color textColor = n.isImportant
                            ? Colors.red.shade900
                            : Colors.black87;
                        final String badge = n.isImportant
                            ? 'IMPORTANT'
                            : 'REGULAR';

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: n.isImportant
                                        ? Colors.red.shade200
                                        : Colors.blue.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isImportant
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: TextStyle(color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'From: ${n.source} | At: ${n.receivedAt}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedNotification {
  final String title;
  final String body;
  final bool isImportant;
  final String source;
  final DateTime receivedAt;

  _ReceivedNotification({
    required this.title,
    required this.body,
    required this.isImportant,
    required this.source,
    required this.receivedAt,
  });
}
