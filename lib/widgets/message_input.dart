import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSubmitted;
  final bool enabled;

  const MessageInput({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
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
        if (!widget.enabled) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isShiftPressed) {
              final text = _controller.text;
              final selection = _controller.selection;
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                '\n',
              );
              _controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start + 1),
              );
              return KeyEventResult.handled;
            } else {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row containing TextField and send button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    hintText:
                        widget.enabled
                            ? 'Message . . .'
                            : 'No active group - Create or join a group to chat',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    filled: !widget.enabled,
                    fillColor: widget.enabled ? null : Colors.grey[100],
                  ),
                  style: TextStyle(fontSize: 16.0, fontFamily: 'Helvetica'),
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  scrollPhysics: ClampingScrollPhysics(),
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                height: 48.0,
                width: 48.0,
                decoration: BoxDecoration(
                  color:
                      widget.enabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.send),
                  color: Theme.of(context).colorScheme.onPrimary,
                  onPressed:
                      widget.enabled
                          ? () {
                            if (_controller.text.isNotEmpty) {
                              widget.onSubmitted(_controller.text);
                              _controller.clear();
                            }
                          }
                          : null,
                ),
              ),
            ],
          ),
          // Helper text below the input row
          SizedBox(height: 4),
          Text(
            'Ctrl+Enter or Shift+Enter for new line',
            style: TextStyle(
              fontSize: 12,
              color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
