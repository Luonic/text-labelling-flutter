import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage_permissions.dart';
import '../session/label_session.dart';
import '../widgets/flag_grid.dart';
import '../widgets/record_card.dart';

class LabellingScreen extends StatefulWidget {
  const LabellingScreen({super.key, required this.session});

  final LabelSession session;

  @override
  State<LabellingScreen> createState() => _LabellingScreenState();
}

class _LabellingScreenState extends State<LabellingScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  String? _openedPath;

  LabelSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      session.save();
    }
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }
    final error = session.takeError();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
    if (session.jsonlPath != _openedPath) {
      _openedPath = session.jsonlPath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(session.currentIndex);
        }
      });
    }
    setState(() {});
  }

  Future<void> _openJsonl() async {
    if (Platform.isAndroid) {
      final allowed = await hasAllFilesAccess();
      if (!allowed && mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Allow file access'),
              content: const Text(
                'Android needs All files access so the app can read images '
                'next to your JSONL file and save flags back to that same file.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
        if (go != true) {
          return;
        }
      }
    }
    await session.pickAndOpen();
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= session.records.length) {
      return;
    }
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _goTo(session.currentIndex + 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _goTo(session.currentIndex - 1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.fileLabel),
                Text(
                  session.progressLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (session.dirty)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Center(child: Text('unsaved')),
                ),
              IconButton(
                tooltip: 'Save',
                onPressed: session.jsonlPath == null ? null : session.save,
                icon: const Icon(Icons.save_outlined),
              ),
              IconButton(
                key: const Key('open-jsonl'),
                tooltip: 'Open JSONL',
                onPressed: session.busy ? null : _openJsonl,
                icon: const Icon(Icons.folder_open),
              ),
            ],
          ),
          body: Stack(
            children: [
              if (session.jsonlPath == null)
                _EmptyState(onOpen: _openJsonl)
              else if (session.records.isEmpty)
                const Center(child: Text('No records in this file'))
              else
                Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: session.records.length,
                        onPageChanged: session.onPageChanged,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Expanded(
                                child: RecordCard(
                                  record: session.records[index],
                                  imagesDir: session.imagesDir ?? '',
                                ),
                              ),
                              FlagGrid(
                                flags: session.flagsFor(index),
                                selected: session.records[index].selectedFlags,
                                onToggle: (flag) =>
                                    session.toggleFlag(flag, index: index),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              if (session.busy)
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x33000000),
                ),
              if (session.busy)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_snippet_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Open a JSONL file to start labelling',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Images are loaded from an images folder next to the file.',
              textAlign: TextAlign.center,
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 8),
              const Text(
                'On Android 11+, grant All files access when asked, then pick the JSONL from device storage (not Drive).',
                textAlign: TextAlign.center,
              ),
            ],
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              const Text(
                'On iPhone and iPad, copy the JSONL and images folder onto the device, then pick that folder in Files (not the JSONL file itself).',
                textAlign: TextAlign.center,
              ),
            ],
            if (Platform.isMacOS) ...[
              const SizedBox(height: 8),
              const Text(
                'On Mac, pick the JSONL file. If thumbnails do not load, pick the folder that contains the file and the images directory.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('open-jsonl-button'),
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open JSONL'),
            ),
          ],
        ),
      ),
    );
  }
}
