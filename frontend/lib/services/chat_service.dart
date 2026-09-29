import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatService {

  static Future<List<ChatMessage>> getChatThread() async {
    debugPrint('FRONTEND LOG: Calling GET /api/chat/thread/lerato');
    await Future.delayed(const Duration(seconds: 1));

    return[
      ChatMessage(id:"message 1", type: ChatMessageType.system),
      ChatMessage(id:"message 2", type: ChatMessageType.quote),
      ChatMessage(
        id: 'message 3',
        type: ChatMessageType.recieved,
        text: "Hello, I reviewed Luke and Josh care sheet'",
        timeStamp: "10:30 AM",
        ),
        ChatMessage(
        id: 'message 4', 
        type: ChatMessageType.sent, 
        text: "Perfect, our ADT panic remote is on the kitchen island. Let me know if you need anything else before check-in.", 
        timeStamp: "10:18 AM"
      ),
      ChatMessage(id: 'message 5', type: ChatMessageType.oversight),
      
    ];
    
  }
}

