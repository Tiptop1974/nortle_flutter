import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:confetti/confetti.dart';
import 'nortle_controller.dart';
import 'models.dart';
import 'widgets/nortle_widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => NortleController(),
      child: const NortleApp(),
    ),
  );
}

class NortleApp extends StatelessWidget {
  const NortleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nortle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const WordleScreen(),
    );
  }
}

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();

    if (!controller.isLoggedIn) {
      return const LoginScreen();
    }

    if (controller.showConfetti) {
      _confettiController.play();
    }

    return Scaffold(
      appBar: AppBar(
        title: const NortleLogo(small: true),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.grey),
          onPressed: () => controller.logout(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const ChatContent(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const ModeSelector(),
                if (controller.gameState == GameState.selectingNumbers)
                  const CountdownSelectionScreen()
                else ...[
                  if (controller.gameMode == GameMode.numbers) const CountdownGameHeader(),
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: controller.errorMessage!.contains("shared") ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (controller.gameState != GameState.playing) const GameEndCard(),
                  const SizedBox(height: 8),
                  if (controller.gameMode == GameMode.words)
                    const WordleGrid()
                  else
                    const CountdownHistory(),
                  const SizedBox(height: 16),
                  const WordleKeyboard(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
          if (controller.showEasterEgg)
            GestureDetector(
              onTap: () => controller.dismissEasterEgg(),
              child: Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: Image.asset('assets/images/easter_egg.png', fit: BoxFit.contain),
              ),
            ),
        ],
      ),
      floatingActionButton: controller.gameMode == GameMode.numbers && controller.gameState != GameState.selectingNumbers
          ? FloatingActionButton.small(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CountdownRulesDialog(),
                );
              },
              child: const Icon(Icons.help_outline),
            )
          : null,
    );
  }
}
