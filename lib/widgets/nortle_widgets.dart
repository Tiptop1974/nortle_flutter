import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../nortle_controller.dart';
import '../models.dart';

class NortleLogo extends StatelessWidget {
  final bool small;
  const NortleLogo({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return GestureDetector(
      onTap: () => controller.onLogoClick(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoSquare("N", const Color(0xFF86A666)),
              const SizedBox(width: 4),
              _logoSquare("O", const Color(0xFFD3AD34)),
              const SizedBox(width: 4),
              _logoSquare("R", const Color(0xFFD3AD34)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoSquare("T", const Color(0xFF86A666)),
              const SizedBox(width: 4),
              _logoSquare("L", const Color(0xFFD3AD34)),
              const SizedBox(width: 4),
              _logoSquare("E", const Color(0xFFD3AD34)),
            ],
          ),
          if (!small) ...[
            const SizedBox(height: 2),
            const Text(
              "NORTLE™",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.black, color: Color(0xFF1A1A1A), letterSpacing: 1),
            ),
            const Text("v1.0", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Text("© 2026 Paul Tippet All Rights Reserved", style: TextStyle(fontSize: 8, color: Colors.grey)),
          ]
        ],
      ),
    );
  }

  Widget _logoSquare(String char, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.center,
      child: Text(char, style: const TextStyle(fontWeight: FontWeight.black, color: Color(0xFF1A1A1A), fontSize: 12)),
    );
  }
}

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(16)),
          child: Text(
            "Daily Challenge ${controller.getFormattedDate()} V${controller.gameNumber}",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<GameMode>(
            segments: const [
              ButtonSegment(value: GameMode.words, label: Text("Words")),
              ButtonSegment(value: GameMode.numbers, label: Text("Math")),
            ],
            selected: {controller.gameMode},
            onSelectionChanged: (Set<GameMode> newSelection) {
              controller.resetGame(newSelection.first);
            },
          ),
        ),
      ],
    );
  }
}

class WordleGrid extends StatelessWidget {
  const WordleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Column(
      children: List.generate(6, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (colIndex) {
              final isSubmitted = rowIndex < controller.guesses.length;
              final isCurrentRow = rowIndex == controller.guesses.length;
              final guess = isSubmitted ? controller.guesses[rowIndex] : (isCurrentRow ? controller.currentGuess : "");
              final char = colIndex < guess.length ? guess[colIndex] : null;
              final status = isSubmitted ? controller.getLetterStatus(rowIndex, colIndex) : LetterStatus.empty;

              return LetterBox(char: char, status: status);
            }),
          ),
        );
      }),
    );
  }
}

class LetterBox extends StatelessWidget {
  final String? char;
  final LetterStatus status;

  const LetterBox({super.key, this.char, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = Colors.black;
    Color borderColor = Colors.grey.shade300;

    switch (status) {
      case LetterStatus.empty:
        break;
      case LetterStatus.notInWord:
        bgColor = const Color(0xFF787C7E);
        textColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case LetterStatus.wrongPosition:
        bgColor = const Color(0xFFC9B458);
        textColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case LetterStatus.correctPosition:
        bgColor = const Color(0xFF6AAA64);
        textColor = Colors.white;
        borderColor = Colors.transparent;
        break;
    }

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        char ?? "",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}

class WordleKeyboard extends StatelessWidget {
  const WordleKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    final screenWidth = MediaQuery.of(context).size.width;

    if (controller.gameMode == GameMode.words) {
      final rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
      return Column(
        children: rows.asMap().entries.map((entry) {
          int rowIndex = entry.key;
          String rowChars = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (rowIndex == 2) _keyBox("ENTER", screenWidth / 10 * 1.5, () => controller.onSubmit()),
                ...rowChars.split('').map((char) {
                  final status = controller.getKeyStatus(char);
                  Color bgColor = Colors.grey.shade300;
                  Color textColor = Colors.black;
                  if (status == LetterStatus.correctPosition) bgColor = const Color(0xFF6AAA64);
                  if (status == LetterStatus.wrongPosition) bgColor = const Color(0xFFC9B458);
                  if (status == LetterStatus.notInWord) bgColor = const Color(0xFF787C7E);
                  if (status != LetterStatus.empty) textColor = Colors.white;

                  return _keyBox(char, screenWidth / 12, () => controller.onKeyPress(char), bgColor: bgColor, textColor: textColor);
                }),
                if (rowIndex == 2) _keyBox(null, screenWidth / 10 * 1.5, () => controller.onDelete(), icon: Icons.backspace_outlined),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.countdownNumbers.take(3).map((num) => Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _keyBox(num.toString(), 0, () => controller.onKeyPress(num.toString()))))).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.countdownNumbers.skip(3).take(3).map((num) => Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _keyBox(num.toString(), 0, () => controller.onKeyPress(num.toString()))))).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: "+-*/()".split('').map((char) => Expanded(child: Padding(padding: const EdgeInsets.all(2.0), child: _keyBox(char, 0, () => controller.onKeyPress(char))))).toList(),
            ),
            Row(
              children: [
                Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _keyBox("ENTER", 0, () => controller.onSubmit()))),
                Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _keyBox(null, 0, () => controller.onDelete(), icon: Icons.backspace_outlined))),
              ],
            )
          ],
        ),
      );
    }
  }

  Widget _keyBox(String? text, double width, VoidCallback onTap, {Color? bgColor, Color? textColor, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width > 0 ? width : null,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: bgColor ?? Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Colors.grey.shade700)
            : Text(text ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: (text?.length ?? 0) > 2 ? 12 : 18, color: textColor ?? Colors.black)),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NortleController>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NortleLogo(),
            const SizedBox(height: 32),
            const Text("Welcome! Please set your username:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.login(_nameController.text),
                child: const Text("Enter Game"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameEndCard extends StatelessWidget {
  const GameEndCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              controller.gameState == GameState.won ? "YOU WON!" : "GAME OVER!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: controller.gameState == GameState.won ? const Color(0xFF6AAA64) : Colors.red),
            ),
            if (controller.gameState == GameState.lost && controller.gameMode == GameMode.words)
              Text("The word was: ${controller.targetValue}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem("Played", controller.gamesPlayed),
                _statItem("Wins", controller.wins),
                _statItem("Streak", controller.currentStreak),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => controller.resetGame(controller.gameMode), child: const Text("New Game")),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => controller.shareResult(), icon: const Icon(Icons.share, size: 18), label: const Text("Share")),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class CountdownSelectionScreen extends StatelessWidget {
  const CountdownSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NortleController>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text("Countdown Numbers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Select how many Large Numbers to use:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const Text("(25, 50, 75, 100)", style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return ElevatedButton(
                onPressed: () => controller.startCountdown(index),
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                child: Text(index.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.black)),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CountdownGameHeader extends StatelessWidget {
  const CountdownGameHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Column(
      children: [
        Text(controller.mathTarget.toString(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.black, color: Theme.of(context).primaryColor)),
        const Text("TARGET", style: TextStyle(color: Colors.grey, letterSpacing: 2)),
        const SizedBox(height: 16),
        const Text("YOUR NUMBERS", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: controller.countdownNumbers.map((num) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(num.toString(), style: const TextStyle(fontWeight: FontWeight.black)),
          )).toList(),
        ),
      ],
    );
  }
}

class CountdownHistory extends StatelessWidget {
  const CountdownHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: Text(
              controller.currentGuess.isEmpty ? "Enter equation..." : controller.currentGuess,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: controller.currentGuess.isEmpty ? Colors.grey.shade400 : Colors.black),
            ),
          ),
          ...controller.guesses.reversed.map((guess) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Text(guess, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          )),
        ],
      ),
    );
  }
}

class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NortleController>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chatting as: ${controller.username}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: controller.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = controller.chatMessages[controller.chatMessages.length - 1 - index];
                return _ChatBubble(message: msg, isMe: msg.sender == controller.username);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(hintText: "Type a message...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (_msgController.text.trim().isNotEmpty) {
                    controller.sendChatMessage(_msgController.text);
                    _msgController.clear();
                  }
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(message.timestamp));
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) Text(message.sender, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(width: 4),
            Text(timeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.type == MessageType.result) _ResultGridImage(message: message),
              Text(message.text),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultGridImage extends StatelessWidget {
  final ChatMessage message;
  const _ResultGridImage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${message.gameMode} Puzzle", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...message.resultGrid.map((row) => Row(
            mainAxisSize: MainAxisSize.min,
            children: row.split('').map((char) => Container(
              width: 12, height: 12, margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: char == 'G' ? const Color(0xFF6AAA64) : (char == 'Y' ? const Color(0xFFC9B458) : const Color(0xFF787C7E)),
                borderRadius: BorderRadius.circular(2),
              ),
            )).toList(),
          )),
        ],
      ),
    );
  }
}

class CountdownRulesDialog extends StatelessWidget {
  const CountdownRulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Countdown Rules"),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("1. Use the 6 numbers provided to reach the target."),
          Text("2. Each number can be used at most once."),
          Text("3. Only +, -, *, / allowed."),
          Text("4. No negative numbers or fractions allowed at any step."),
          SizedBox(height: 8),
          Text("Tip: You don't have to use all 6 numbers!", style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
    );
  }
}
