import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSubmitted;

  const MessageInput({
    super.key,
    required this.onSubmitted,
  });

  @override
  MessageInputState createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            // Check if Ctrl or Shift is pressed
            if (HardwareKeyboard.instance.isControlPressed || 
                HardwareKeyboard.instance.isShiftPressed) {
              // Insert a newline character at the current cursor position
              final text = _controller.text;
              final selection = _controller.selection;
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                '\n',
              );
              _controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.start + 1,
                ),
              );
              return KeyEventResult.handled;
            } else {
              // Submit the message
              if (_controller.text.isNotEmpty) {
                widget.onSubmitted(_controller.text);
                _controller.clear();
              }
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Message . . .',
                border: OutlineInputBorder(),
                helperText: 'Ctrl+Enter or Shift+Enter for new line',
                helperStyle: TextStyle(fontSize: 12),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'Helvetica',
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
          SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: IconButton(
              icon: Icon(Icons.send),
              color: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.all(12),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  widget.onSubmitted(_controller.text);
                  _controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
