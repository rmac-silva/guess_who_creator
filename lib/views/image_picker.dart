import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/models/game.dart';
import 'package:guess_who_creator/modelviews/image_upload_viewmodel.dart';
import 'package:guess_who_creator/utils/error_helper_view.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({super.key});

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  // Instantiate the ViewModel
  final ImageUploadViewModel _viewModel = ImageUploadViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    // ListenableBuilder listens to the ViewModel's notifyListeners() calls
    return Padding(
      padding: EdgeInsetsGeometry.directional(top: 30, start: 15, end: 15),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _GameTitle(
                    gameTitle: _viewModel.game.gameName,
                    onTitleChange: (newTitle) => {
                      _viewModel.changeGameName(newTitle),
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    spacing: 18,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BUTTON 1: Pick Images
                      ElevatedButton.icon(
                        onPressed: _viewModel.isUploading
                            ? null
                            : _viewModel.pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Select Images'),

                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          backgroundColor: themeProvider.isDarkMode
                              ? darkTheme.highlightColor
                              : lightTheme.highlightColor,
                          foregroundColor: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      if (_viewModel.gameEntries.isNotEmpty) ...[
                        //Button 2, game creation
                        Tooltip(
                          message: _viewModel.game.gameName.isEmpty
                              ? 'Please enter a name for your game first.'
                              : _viewModel.hasUnlabeledImages
                              ? 'All uploaded images must have a guess label.'
                              : _viewModel.isUploading
                              ? 'Please wait for your images to finish uploading...'
                              : '',

                          waitDuration: const Duration(milliseconds: 200),
                          showDuration: const Duration(seconds: 2),
                          child: Container(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_viewModel.hasUnlabeledImages ||
                                      _viewModel.isUploading ||
                                      _viewModel.game.gameName.isEmpty)
                                  ? null
                                  : () {
                                      final mainPageContext = context;

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return EmailCaptureModal(
                                            onSubmit: (submittedEmail) async {
                                              Navigator.of(context).pop();

                                              await Future.microtask(() {});
                                              try {
                                                var res = await _viewModel
                                                    .createGame(submittedEmail);

                                                if (!mainPageContext.mounted) {
                                                  return;
                                                }

                                                String title =
                                                    "Game Created Successfuly";
                                                String message =
                                                    _viewModel.generatedMessage;
                                                String gameLink =
                                                    _viewModel.gameID;

                                                final uri = Uri(
                                                  path: '/new_game/success',
                                                  queryParameters: {
                                                    'title': title,
                                                    'message': message,
                                                    'id': gameLink,
                                                  },
                                                );

                                                Routemaster.of(
                                                  mainPageContext,
                                                ).push(uri.toString());
                                              } catch (e) {
                                                ErrorBanner.show(
                                                  mainPageContext,
                                                  "Failed to upload images: ${e.toString()}",
                                                  duration: Duration(
                                                    seconds: 6,
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                              icon:
                                  (_viewModel.hasUnlabeledImages ||
                                      _viewModel.isUploading ||
                                      _viewModel.game.gameName.isEmpty)
                                  ? const Icon(Icons.close)
                                  : const Icon(Icons.check),
                              label: const Text('Create Game'),

                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 50),
                                backgroundColor: themeProvider.isDarkMode
                                    ? Colors.green.shade800
                                    : Colors.green.shade300,
                                foregroundColor: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                disabledBackgroundColor:
                                    themeProvider.isDarkMode
                                    ? Colors.red.shade500
                                    : Colors.red.shade300,
                                disabledForegroundColor:
                                    themeProvider.isDarkMode
                                    ? Colors.white.withAlpha(150)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // IMAGE PREVIEW ZONE
                  if (_viewModel.gameEntries.isNotEmpty) ...[
                    AlignedGridView.extent(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      maxCrossAxisExtent:
                          300, // Moves into the constructor directly
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      itemCount: _viewModel.gameEntries.length,
                      itemBuilder: (context, index) {
                        final guess = _viewModel.gameEntries[index];
                        return _ImageGuessEntry(
                          guessPair: guess,
                          hasHints: _viewModel.hasHints,
                          hasMultipleGuesses: _viewModel.hasMultipleGuesses,
                          onDelete: () => _viewModel.removeImage(guess.guessId),
                          onCluesChange: (updatedClues) => _viewModel
                              .changeImageClues(guess.guessId, updatedClues),
                          onLabelsChange: (updatedlabels) => _viewModel
                              .changeImageLabels(guess.guessId, updatedlabels),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    const Text(
                      'No images selected yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),

              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.settings, size: 28),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return GameSettingsModal(
                          hasHints: _viewModel
                              .hasHints, // or wherever your state variables live
                          hasMultipleGuesses: _viewModel.hasMultipleGuesses,
                          onHasHintsChange: (val) {
                            setState(() => _viewModel.toggleHints(val));
                          },
                          onMultipleGuessChange: (val) {
                            setState(
                              () => _viewModel.toggleMultipleGuesses(val),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageGuessEntry extends StatelessWidget {
  final ImageGuess guessPair;
  final VoidCallback onDelete;
  final bool hasMultipleGuesses;
  final bool hasHints;
  final ValueChanged<List<String>> onLabelsChange;
  final ValueChanged<List<String>> onCluesChange;

  const _ImageGuessEntry({
    required this.guessPair,
    required this.onDelete,
    required this.hasHints,
    required this.hasMultipleGuesses,
    required this.onCluesChange,
    required this.onLabelsChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Padding(
        padding: EdgeInsetsGeometry.directional(),
        child: Column(
          children: [
            _ImageThumbnail(image: guessPair.image, onDelete: onDelete),
            _ImageLabel(
              labels: guessPair.guessNames,
              onLabelsChange: onLabelsChange,
              clues: guessPair.clues,
              onCluesChange: onCluesChange,
              hasHints: hasHints,
              hasMultipleGuesses: hasMultipleGuesses,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageLabel extends StatefulWidget {
  final List<String> labels;
  final List<String> clues;
  final bool hasMultipleGuesses;
  final bool hasHints;

  // Broadened callbacks to update entire collections
  final ValueChanged<List<String>> onLabelsChange;
  final ValueChanged<List<String>> onCluesChange;

  const _ImageLabel({
    super.key,
    required this.labels,
    required this.clues,
    required this.hasHints,
    required this.hasMultipleGuesses,
    required this.onLabelsChange,
    required this.onCluesChange,
  });

  @override
  State<StatefulWidget> createState() => _ImageLabelState();
}

class _ImageLabelState extends State<_ImageLabel> {
  // Lists of controllers to map 1:1 to your incoming data lists
  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _clueControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers(_labelControllers, widget.labels);
    _syncControllers(_clueControllers, widget.clues);
  }

  @override
  void didUpdateWidget(covariant _ImageLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers(_labelControllers, widget.labels);
    _syncControllers(_clueControllers, widget.clues);
  }

  // Helper function to safely spin up/down controllers based on data changes
  void _syncControllers(
    List<TextEditingController> controllers,
    List<String> data,
  ) {
    // If data grew, add new controllers
    while (controllers.length < data.length) {
      controllers.add(TextEditingController());
    }
    // If data shrank, remove extra controllers
    while (controllers.length > data.length) {
      controllers.last.dispose();
      controllers.removeLast();
    }
    // Sync text values without breaking text cursor positions
    for (int i = 0; i < data.length; i++) {
      if (controllers[i].text != data[i]) {
        controllers[i].text = data[i];
      }
    }
  }

  @override
  void dispose() {
    for (var c in _labelControllers) {
      c.dispose();
    }
    for (var c in _clueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Helper widget builder for dynamic inputs (Guesses or Clues)
  Widget _buildDynamicInputField({
    required String title,
    required String hint,
    required IconData icon,
    required List<String> dataList,
    required List<TextEditingController> controllers,
    required ValueChanged<List<String>> onListChanged,
    required bool allowMultiple,
    required bool alwaysDelete
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        ...List.generate(allowMultiple ? dataList.length : 1, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    onChanged: (newValue) {
                      List<String> updatedList = List.from(dataList);
                      updatedList[index] = newValue;
                      onListChanged(updatedList);
                      setState(() {});
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '$hint ${index + 1}',
                      prefixIcon: Icon(icon, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: controllers[index].text.isEmpty
                              ? Colors.red.shade400
                              : Colors.green.shade500,
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                // Show a delete button only if there's more than 1 item and settings allow it
                if (allowMultiple && (dataList.length > 1 || alwaysDelete))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      List<String> updatedList = List.from(dataList);
                      updatedList.removeAt(index);
                      onListChanged(updatedList);
                    },
                  ),
              ],
            ),
          );
        }),
        // Add item button (Shows if multiple guesses are allowed, or if it's a clue section)
        if (allowMultiple)
          TextButton.icon(
            onPressed: () {
              List<String> updatedList = List.from(dataList);
              updatedList.add(""); // Push an empty placeholder string
              onListChanged(updatedList);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add $title'),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. GUESSES SECTION
        _buildDynamicInputField(
          title: 'Correct Guess',
          hint: 'Enter guess option',
          icon: Icons.label_outline,
          dataList: widget.labels,
          controllers: _labelControllers,
          onListChanged: widget.onLabelsChange,
          allowMultiple:
              widget.hasMultipleGuesses, // Tied to your settings bool
          alwaysDelete: false
        ),

        // 2. HINTS SECTION (Conditionally shown based on hasHints setting)
        if (widget.hasHints) ...[
          const Divider(),
          _buildDynamicInputField(
            title: 'Game Hint',
            hint: 'Enter dynamic hint',
            icon: Icons.help_outline,
            dataList: widget.clues,
            controllers: _clueControllers,
            onListChanged: widget.onCluesChange,
            allowMultiple: true, // Clues are natively infinite per your request
            alwaysDelete: true
          ),
        ],
      ],
    );
  }
}

// A helper sub-widget to display individual image thumbnails and status badges
class _ImageThumbnail extends StatelessWidget {
  final UploadedImageModel image;
  final VoidCallback onDelete;

  const _ImageThumbnail({required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(image.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Stack(
            children: [
              // The image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  image.bytes,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              // Dark overlay sheet while uploading
              if (image.status == UploadStatus.uploading)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              // Delete Button (Only visible if not currently uploading)
              if (image.status != UploadStatus.uploading)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),

              // Status Indicators (Success Checkmark or Error Warning)
              if (image.status == UploadStatus.success)
                const Positioned(
                  bottom: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
              if (image.status == UploadStatus.error)
                const Positioned(
                  bottom: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameTitle extends StatefulWidget {
  final String gameTitle;
  final ValueChanged<String> onTitleChange;

  const _GameTitle({required this.gameTitle, required this.onTitleChange});

  @override
  State<StatefulWidget> createState() => _GameTitleState();
}

class _GameTitleState extends State<_GameTitle> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller once when this specific cell appears on screen
    _controller = TextEditingController(text: widget.gameTitle);
  }

  @override
  void didUpdateWidget(covariant _GameTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the label data structure updates from the outside, sync our controller text
    if (widget.gameTitle != _controller.text) {
      _controller.text = widget.gameTitle;
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoSizeTextField(
      // 2. Use AutoSizeTextField instead of TextField
      controller: _controller,
      onChanged: (value) {
        widget.onTitleChange(value);
        // Look mom, no setState(() {}) required just for resizing!
        // The package handles its own internal repaints smoothly.
      },
      textAlign: TextAlign.center,
      minWidth: widget.gameTitle.isEmpty ? 500 : 0,
      fullwidth: false,
      style: const TextStyle(fontSize: 28),
      decoration: const InputDecoration(
        hintText: "The name or topic of the game",
      ),
    );
  }
}

class EmailCaptureModal extends StatefulWidget {
  final Function(String email) onSubmit;

  const EmailCaptureModal({super.key, required this.onSubmit});

  @override
  State<EmailCaptureModal> createState() => _EmailCaptureModalState();
}

class _EmailCaptureModalState extends State<EmailCaptureModal> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Validation

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    return AlertDialog(
      title: const Text("Additional Information"),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "The link to access your finished game will be provided in this page, and optionally, in your email as well.\nIf you want to edit this game in the future, please provide your email so we can give you a link to do so.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.getTextColor().withAlpha(220),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "example@email.com",
                    labelText: "Email (Optional)",
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null ||
                        (value.isNotEmpty && !value.contains('@'))) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(140, 45),
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.red.shade900
                    : Colors.red.shade100,
                foregroundColor: themeProvider.getTextColor(),
                side: BorderSide(
                  color: themeProvider.getTextColor().withAlpha(100),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit(_emailController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 45),
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.green.shade800
                    : Colors.green.shade300,
                foregroundColor: themeProvider.getTextColor(),
                side: BorderSide(
                  color: themeProvider.getTextColor().withAlpha(100),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Create Game"),
            ),
          ],
        ),
      ],
    );
  }
}

class GameSettingsModal extends StatefulWidget {
  final bool hasMultipleGuesses;
  final bool hasHints;

  final ValueChanged<bool> onMultipleGuessChange;
  final ValueChanged<bool> onHasHintsChange;

  const GameSettingsModal({
    super.key,
    required this.hasHints,
    required this.hasMultipleGuesses,
    required this.onHasHintsChange,
    required this.onMultipleGuessChange,
  });

  @override
  State<GameSettingsModal> createState() => _GameSettingsModalState();
}

class _GameSettingsModalState extends State<GameSettingsModal> {
  // Late variables to track local state changes before the user closes the modal
  late bool _localHasMultipleGuesses;
  late bool _localHasHints;

  @override
  void initState() {
    super.initState();
    // Initialize our local switches with the current settings passed from the parent
    _localHasMultipleGuesses = widget.hasMultipleGuesses;
    _localHasHints = widget.hasHints;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game Settings'),
      content: Column(
        mainAxisSize: MainAxisSize
            .min, // Prevents the modal from taking up the whole screen
        children: [
          SwitchListTile(
            title: const Text('Multiple Correct Guesses'),
            subtitle: const Text(
              'Allows you to specify multiple correct guesses',
            ),
            value: _localHasMultipleGuesses,
            onChanged: (bool value) {
              setState(() {
                _localHasMultipleGuesses = value;
              });
              // Notify the parent widget immediately of the change
              widget.onMultipleGuessChange(value);
            },
          ),
          SwitchListTile(
            title: const Text('Enable Hints'),
            subtitle: const Text(
              'Enable clues. You can specify any amount of clues. Each clue will be revealed after 5 wrong guesses.',
            ),
            value: _localHasHints,
            onChanged: (bool value) {
              setState(() {
                _localHasHints = value;
              });
              // Notify the parent widget immediately of the change
              widget.onHasHintsChange(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
