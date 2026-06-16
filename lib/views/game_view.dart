import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/models/game.dart';
import 'package:guess_who_creator/modelviews/game_viewmodel.dart';
import 'package:guess_who_creator/utils/error_helper_view.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:guess_who_creator/views/links.dart';
import 'package:guess_who_creator/views/theme_switch.dart';
import 'package:guess_who_creator/views/victory_modal.dart';

class GameView extends StatefulWidget {
  final String gameID;

  const GameView({super.key, required this.gameID});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  //final GameViewModel _viewModel = new GameViewModel(widget.gameID) - Cannot use this
  //Because the widget would refresh and change it's initial state. If you want to
  //initialize things, do it in initState

  late final GameViewModel _viewModel;
  bool _modalShown = false;

  @override
  void initState() {
    super.initState();
    _viewModel = GameViewModel(widget.gameID);
    _viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;

    // Check for errors
    if (_viewModel.errorMessage != null) {
      ErrorBanner.show(context, _viewModel.errorMessage!);
    }

    // Check for victory
    if (_viewModel.wonGame && !_modalShown) {
      _modalShown = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => VictoryModal(
          correctGuesses: _viewModel.correctAnswers ?? [],
          totalAttempts: _viewModel.previousGuesses.length,
          image: _viewModel.image,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final themeProvider = ThemeProvider.of(context);

    // 1. Establish your responsive layout flag
    final bool isLargeScreen = screenSize.width > 768;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_viewModel.gameTitle ?? ""),
            actions: [
              GameHintButton(
                onTap: () => _viewModel.showClue(),
                disabled: !_viewModel.hasNextClue(),
              ),
              ThemeSwitch(
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.onThemeChanged,
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenSize.height * 0.867,
                  ),
                  child: Container(
                    color: themeProvider.isDarkMode
                        ? darkTheme.primaryColor
                        : lightTheme.primaryColor,
                    width: screenSize.width,
                    child: _viewModel.isLoading
                        ? Center(
                            child: SizedBox(
                              width: screenSize.width / 1920 * 160,
                              height: screenSize.height / 1080 * 90,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Padding(
                            // Add universal core container padding
                            padding: const EdgeInsets.all(16.0),
                            // 2. Use a Flex layout. Stacks vertically on mobile, horizontally on desktop!
                            child: Flex(
                              direction: isLargeScreen
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              crossAxisAlignment: isLargeScreen
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              // Tighten spaces up between vertical elements on mobile
                              spacing: isLargeScreen ? 0 : 20,
                              children: [
                                // --- PREVIOUS GUESSES PANEL ---
                                _buildResponsivePanel(
                                  isLargeScreen: isLargeScreen,
                                  flex: 1,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      // Give it a fixed height boundary on mobile so it scrolls cleanly
                                      maxHeight: isLargeScreen
                                          ? screenSize.height * 0.81
                                          : 180,
                                    ),
                                    child: PreviousGuessesWidget(
                                      correctGuesses:
                                          _viewModel.correctAnswers ?? [],
                                      guesses: _viewModel.previousGuesses,
                                    ),
                                  ),
                                ),

                                // --- CORE GAME MAIN INTERFACE ---
                                _buildResponsivePanel(
                                  isLargeScreen: isLargeScreen,
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GameImageView(image: _viewModel.image),
                                      const SizedBox(height: 24),
                                      GuessInputField(
                                        onGuessSubmitted: (newGuess) {
                                          _viewModel.addGuess(newGuess);
                                        },
                                        gameIsWon: _viewModel.wonGame,
                                      ),
                                    ],
                                  ),
                                ),

                                // --- GAME CLUES PANEL ---
                                _buildResponsivePanel(
                                  isLargeScreen: isLargeScreen,
                                  flex: 1,
                                  child: GameCluesDisplay(
                                    clues: _viewModel.clues ?? [],
                                    clueIndex: _viewModel.clueIndex,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 70,
                    maxHeight: screenSize.height * 0.6 > 70
                        ? screenSize.height * 0.6
                        : 70,
                  ),
                  child: Container(
                    height: screenSize.height * 0.06,
                    color: themeProvider.isDarkMode
                        ? darkTheme.dividerColor
                        : lightTheme.dividerColor,
                    alignment: Alignment.center,
                    child: LinkFooter(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Helper layout adapter method
  Widget _buildResponsivePanel({
    required bool isLargeScreen,
    required int flex,
    required Widget child,
  }) {
    if (isLargeScreen) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          key:
              UniqueKey(), // Forces fresh calculation constraints on screen resize
          child: child,
        ),
      );
    }

    // On Mobile, remove Expanded wraps completely so components expand to fill 100% device width
    return SizedBox(width: double.infinity, child: child);
  }
}

class PreviousGuessesWidget extends StatefulWidget {
  final List<String> guesses;
  final List<String> correctGuesses;

  const PreviousGuessesWidget({
    super.key,
    required this.guesses,
    required this.correctGuesses,
  });

  @override
  State<StatefulWidget> createState() => _PreviousGuessesState();
}

class _PreviousGuessesState extends State<PreviousGuessesWidget> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    if (widget.guesses.isEmpty) {
      return Center(
        child: Text(
          "No guesses made yet...",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: themeProvider.isDarkMode
                ? Colors.white.withAlpha((0.8 * 255).floor())
                : Colors.black.withAlpha((0.8 * 255).floor()),
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: widget.guesses.length,
        itemBuilder: (context, index) {
          final reversedIndex = (widget.guesses.length - 1) - index;
          final guess = widget.guesses[reversedIndex];

          final isLatestGuess = (index == 0);
          
          final cleanedGuess = guess.trim().toLowerCase();
          final isCorrectGuess = (index == 0 &&
              widget.correctGuesses.any(
                (entry) => entry.trim().toLowerCase() == cleanedGuess,
              ));

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: isCorrectGuess
                ? themeProvider.getSuccessColor()
                : (isLatestGuess
                      ? themeProvider.getErrorColor().withAlpha(220)
                      : themeProvider.getErrorColor().withAlpha(190)),
            shape: isLatestGuess
                ? RoundedRectangleBorder(
                    side: BorderSide(
                      color: themeProvider.getTextColor(),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: ListTile(
              title: Text(
                guess,
                style: TextStyle(
                  fontWeight: isLatestGuess ? FontWeight.bold : FontWeight.w500,
                  decoration: isLatestGuess
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                  color: isLatestGuess
                      ? themeProvider.getTextColor()
                      : themeProvider.getTextColor().withAlpha(204),
                ),
              ),
              trailing: Text(
                'Attempt #${reversedIndex + 1}',
                style: TextStyle(
                  color: themeProvider.getTextColor().withAlpha(190),
                  fontSize: 12,
                  fontWeight: isLatestGuess
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      );
    }
  }
}

class GameImageView extends StatefulWidget {
  final UploadedImageModel? image;

  const GameImageView({super.key, required this.image});

  @override
  State<GameImageView> createState() => _GameImageViewState();
}

class _GameImageViewState extends State<GameImageView> {
  ui.Image? _decodedImage;
  bool _isDecoding = false;

  @override
  void initState() {
    super.initState();
    _decodeImageDimensions();
  }

  @override
  void didUpdateWidget(GameImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _decodeImageDimensions();
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  // Reads the raw pixel matrix to calculate the real aspect ratio
  Future<void> _decodeImageDimensions() async {
    if (widget.image == null) {
      if (mounted) {
        setState(() {
          _decodedImage?.dispose();
          _decodedImage = null;
        });
      }
      return;
    }

    if (mounted) setState(() => _isDecoding = true);

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        widget.image!.bytes,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      if (!mounted) {
        frameInfo.image.dispose();
        return;
      }

      setState(() {
        _decodedImage?.dispose(); // Dispose previous if any
        _decodedImage = frameInfo.image;
        _isDecoding = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _decodedImage?.dispose();
          _decodedImage = null;
          _isDecoding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = ThemeProvider.of(context);

    // Fallback if no image is provided yet
    if (widget.image == null || _isDecoding) {
      return Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.grey[800]!
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    // Calculate the aspect ratio dynamically (defaults to 1.0 square if lookup fails)
    final double aspectRatio = _decodedImage != null
        ? _decodedImage!.width / _decodedImage!.height
        : 1.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Enforce minimum size so small 128x128 textures upscale nicely
          minWidth: 350,
          minHeight: 350,
          // Limit maximum bounds relative to screen size so it stays within viewports
          maxWidth: screenSize.width * 0.45,
          maxHeight: screenSize.height * 0.50,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              widget.image!.bytes,
              // BoxFit.contain ensures zero clipping while matching layout scale limits
              fit: BoxFit.contain,
              filterQuality: FilterQuality
                  .medium, // Keeps upscaled 128x128 pixels looking clean
            ),
          ),
        ),
      ),
    );
  }
}

class GuessInputField extends StatefulWidget {
  final ValueChanged<String> onGuessSubmitted;
  final bool gameIsWon;

  const GuessInputField({
    super.key,
    required this.onGuessSubmitted,
    required this.gameIsWon,
  });

  @override
  State<GuessInputField> createState() => _GuessInputFieldState();
}

class _GuessInputFieldState extends State<GuessInputField> {
  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  void _submitAction() {
    if (widget.gameIsWon) return;

    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onGuessSubmitted(text);
      _controller.clear();
    }

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    // Check available width to determine if we are on a tight mobile screen
    final double availableWidth = MediaQuery.of(context).size.width;
    final bool isShortScreen = availableWidth < 360;

    return Row(
      children: [
        Expanded(
          child: TextField(
            enabled: !widget.gameIsWon,
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(color: themeProvider.getTextColor()),
            decoration: InputDecoration(
              hintText: "Type your guess...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: themeProvider.getPrimaryColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (_) => widget.gameIsWon ? null : _submitAction(),
          ),
        ),
        const SizedBox(width: 8), // Snugged up from 12 to save space
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            // Reduce horizontal padding on small screens to give the input more room
            padding: EdgeInsets.symmetric(
              horizontal: isShortScreen ? 12 : 20,
              vertical: 14,
            ),
            backgroundColor: themeProvider.getSecondaryColor(),
            foregroundColor: themeProvider.getTextColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: widget.gameIsWon ? null : _submitAction,
          // Shows just a clean arrow icon if the screen is critically narrow
          child: isShortScreen
              ? const Icon(Icons.send, size: 18)
              : const Text("Submit"),
        ),
      ],
    );
  }
}

class GameStatusBar extends StatefulWidget {
  final bool gameIsWon;
  final String Function() getBanter;
  final String Function() getVictoryPhrase;

  const GameStatusBar({
    super.key,
    required this.gameIsWon,
    required this.getBanter,
    required this.getVictoryPhrase,
  });

  @override
  State<GameStatusBar> createState() => _GameStatusBarState();
}

class _GameStatusBarState extends State<GameStatusBar> {
  late String _displayedPhrase;

  @override
  void initState() {
    super.initState();
    // Pick initial banter phrase
    _displayedPhrase = "";
  }

  @override
  void didUpdateWidget(GameStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the game state changes from playing -> won, trigger a victory phrase swap!
    if (!oldWidget.gameIsWon && widget.gameIsWon) {
      setState(() {
        _displayedPhrase = widget.getVictoryPhrase();
      });
    } else {
      setState(() {
        _displayedPhrase = widget.getBanter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Text(
          _displayedPhrase,
          key: ValueKey<String>(
            _displayedPhrase,
          ), // Necessary for clean animation swap
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: widget.gameIsWon
                ? themeProvider.getSuccessColor()
                : themeProvider.getTextColor(),
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black38,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameHintButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool disabled;

  const GameHintButton({
    super.key,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'No more hints' : 'Give me a hint!',
      waitDuration: const Duration(
        milliseconds: 400,
      ), // Time before it pops up on hover
      showDuration: const Duration(seconds: 2), // How long it stays visible
      preferBelow: false, // Display above the bulb so fingers don't block it
      child: IconButton(
        icon: Icon(Icons.lightbulb, size: 28),
        // Uses amber yellow if turned "on", otherwise falls back to theme default
        color: disabled ? Colors.grey : Colors.amber,
        onPressed: disabled ? null : onTap,
        splashRadius: 24,
      ),
    );
  }
}

class GameCluesDisplay extends StatelessWidget {
  final List<String> clues;
  final int clueIndex;

  const GameCluesDisplay({
    super.key,
    required this.clues,
    required this.clueIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 1. COMPLETELY INVISIBLE GUARD
    // If clueIndex is 0 (no hints used yet) or the list itself is empty, render nothing
    if (clueIndex <= 0 || clues.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. FILTER REVEALED CLUES
    // Take clues up to the current index. If clueIndex is 2, it takes index 0 and 1.
    final revealedClues = clues.take(clueIndex).toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3. RESIZABLE TEXT HEADER
          const AutoSizeText(
            'Clues',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          const SizedBox(height: 10),

          // 4. LIST OF REVEALED CLUES
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: revealedClues.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        revealedClues[index],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
