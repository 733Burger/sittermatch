enum ChatMessageType { quote, sent, recieved, system, oversight }

class ChatMessage {
  final String id;
  final String? text;
  final String? timeStamp;
  final ChatMessageType type;


ChatMessage( {
  required this.id,
   this.text,
   this.timeStamp,
  required this.type,

});

}

