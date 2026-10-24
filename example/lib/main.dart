import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:wic_decode/wic_decode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _wicDecodePlugin = WicDecode();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  String _srcPath = '';
  String _destPath = '';
  String _status = '';
  ui.Image? _decodedImage;
  int _orientation = 1;

  static const String _samplePngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAHklEQVQI12P4'
      '//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==';

  Future<void> _pickSource() async {
    final XFile? file = await openFile();
    if (file == null) return;
    final dest = File(p.join(Directory.systemTemp.path, 'wic_output.raw'));
    _disposeImage();
    setState(() {
      _srcPath = file.path;
      _destPath = dest.path;
      _status = 'Source selected. Output will be written to $_destPath';
    });
    _decode();
  }

  Future<void> _createSampleSource() async {
    try {
      final bytes = base64Decode(_samplePngBase64);
      final src = File(p.join(Directory.systemTemp.path, 'wic_sample.png'));
      final dest = File(p.join(Directory.systemTemp.path, 'wic_output.raw'));
      await src.writeAsBytes(bytes, flush: true);
      _disposeImage();
      setState(() {
        _srcPath = src.path;
        _destPath = dest.path;
        _status = 'Sample source created.';
      });
      _decode();
    } catch (e) {
      setState(() => _status = 'Failed to create sample: $e');
    }
  }

  void _disposeImage() {
    _decodedImage?.dispose();
    _decodedImage = null;
  }

  Future<void> _decode() async {
    if (_srcPath.isEmpty || _destPath.isEmpty) {
      setState(() => _status = 'Please pick a source image first.');
      return;
    }
    int? width;
    int? height;
    if (_widthController.text.trim().isNotEmpty) {
      width = int.tryParse(_widthController.text.trim());
    }
    if (_heightController.text.trim().isNotEmpty) {
      height = int.tryParse(_heightController.text.trim());
    }
    if ((width == null) != (height == null)) {
      setState(() => _status = 'Provide both width and height, or neither.');
      return;
    }
    setState(() => _status = 'Decoding...');
    try {
      final result = await _wicDecodePlugin.decodeImageToRawPixelFile(
        srcImage: _srcPath,
        destFile: _destPath,
        outWidth: width,
        outHeight: height,
      );
      final length = await File(_destPath).length();

      final imageWidth = result.width;
      final imageHeight = result.height;
      final orientation = result.orientation;

      final image = await _wicDecodePlugin.decodeRawPixelFileToUIImage(
        filePath: _destPath,
        width: imageWidth,
        height: imageHeight,
      );
      _disposeImage();
      setState(() {
        _decodedImage = image;
        _orientation = orientation;
        _status =
            'Success: wrote $length raw bytes to $_destPath (orientation: $orientation)';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  void dispose() {
    _disposeImage();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('wic_decode example')),
        body: SelectionArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _srcPath.isEmpty
                      ? 'No source selected.'
                      : 'Source: $_srcPath',
                ),
                Text(_destPath.isEmpty ? '' : 'Output: $_destPath'),
                const SizedBox(height: 12),
                TextField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Output width (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Output height (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickSource,
                  child: const Text('Pick source image'),
                ),
                ElevatedButton(
                  onPressed: _createSampleSource,
                  child: const Text('Create sample source image'),
                ),
                const SizedBox(height: 12),
                Text(_status),
                const SizedBox(height: 12),
                if (_decodedImage != null)
                  Expanded(child: WicDecode.buildImageViewFromUIImage(_decodedImage!, _orientation)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
