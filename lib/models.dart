enum GameState {
  playing,
  won,
  lost,
  selectingNumbers,
}

enum LetterStatus {
  empty,
  notInWord,
  wrongPosition,
  correctPosition,
}

enum GameMode {
  words,
  numbers,
}

enum MessageType {
  text,
  result,
}

class ChatMessage {
  final String sender;
  final String text;
  final int timestamp;
  final MessageType type;
  final List<String> resultGrid;
  final String target;
  final String gameMode;

  ChatMessage({
    this.sender = '',
    this.text = '',
    this.timestamp = 0,
    this.type = MessageType.text,
    this.resultGrid = const [],
    this.target = '',
    this.gameMode = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
      'type': type.name.toUpperCase(),
      'resultGrid': resultGrid,
      'target': target,
      'gameMode': gameMode,
    };
  }

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      type: json['type'] == 'RESULT' ? MessageType.result : MessageType.text,
      resultGrid: List<String>.from(json['resultGrid'] ?? []),
      target: json['target'] ?? '',
      gameMode: json['gameMode'] ?? '',
    );
  }
}
