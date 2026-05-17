import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

Future<Uint8List?> showAvatarCropDialog({
  required BuildContext context,
  required Uint8List imageBytes,
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AvatarCropDialog(imageBytes: imageBytes),
  );
}

class _AvatarCropDialog extends StatefulWidget {
  const _AvatarCropDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<_AvatarCropDialog> {
  static const _outputSize = 640;
  static const _minScale = 1.0;
  static const _maxScale = 4.0;

  ui.Image? _image;
  Object? _decodeError;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _scale = 1;
  double _startScale = 1;
  double _viewportSize = 340;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    unawaited(_decodeImage());
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final image = await _decodeUiImage(widget.imageBytes);

      if (!mounted) {
        image.dispose();
        return;
      }

      setState(() => _image = image);
    } catch (error) {
      if (mounted) {
        setState(() => _decodeError = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.tintOf(context, AppColors.actionBlue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.crop_free_outlined,
                      color: AppColors.actionBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajustar foto de perfil',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textOf(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Mueve y acerca la imagen hasta que el rostro quede centrado.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.subduedOf(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cropping ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_decodeError != null)
                _CropMessage(
                  icon: Icons.error_outline,
                  title: 'No se pudo leer la imagen',
                  message: 'Prueba con una foto JPG, PNG o WEBP.',
                  color: AppColors.danger,
                )
              else if (_image == null)
                const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportSize = math.min(
                        constraints.maxWidth,
                        340.0,
                      );
                      _viewportSize = viewportSize;

                      return _CropViewport(
                        image: _image!,
                        imageBytes: widget.imageBytes,
                        offset: _offset,
                        scale: _scale,
                        size: viewportSize,
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: (details) =>
                            _handleScaleUpdate(details, viewportSize),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                      Icons.zoom_out_rounded,
                      color: AppColors.subduedOf(context),
                    ),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: _minScale,
                        max: _maxScale,
                        onChanged: _cropping
                            ? null
                            : (value) {
                                setState(() {
                                  _scale = value;
                                  _offset = _clampOffsetForViewport(
                                    _offset,
                                    value,
                                  );
                                });
                              },
                      ),
                    ),
                    Icon(
                      Icons.zoom_in_rounded,
                      color: AppColors.subduedOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CropMessage(
                  icon: Icons.touch_app_outlined,
                  title: 'Recorte cuadrado optimizado',
                  message:
                      'SIGCAL guardara solo esta zona para que encaje en el dock y en tu perfil.',
                  color: AppColors.actionBlue,
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _cropping || _image == null
                        ? null
                        : () {
                            setState(() {
                              _offset = Offset.zero;
                              _scale = 1;
                            });
                          },
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Recentrar'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _cropping ? null : () => Navigator.pop(context),
                    child: Text(''),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _image == null || _cropping ? null : _crop,
                    icon: _cropping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_cropping ? 'Cortando...' : 'Usar recorte'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _startOffset = _offset;
    _startScale = _scale;
    _startFocalPoint = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double viewportSize) {
    final image = _image;

    if (image == null || _cropping) {
      return;
    }

    final nextScale = (_startScale * details.scale).clamp(_minScale, _maxScale);
    final nextOffset = _startOffset + details.focalPoint - _startFocalPoint;

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(
        image: image,
        viewportSize: viewportSize,
        offset: nextOffset,
        scale: nextScale,
      );
    });
  }

  Offset _clampOffsetForViewport(Offset offset, double scale) {
    final image = _image;

    if (image == null) {
      return offset;
    }

    return _clampOffset(
      image: image,
      viewportSize: _viewportSize,
      offset: offset,
      scale: scale,
    );
  }

  Future<void> _crop() async {
    final image = _image;

    if (image == null) {
      return;
    }

    setState(() => _cropping = true);

    try {
      final croppedBytes = await _renderCrop(
        image: image,
        offset: _offset,
        scale: _scale,
        viewportSize: _viewportSize,
      );

      if (mounted) {
        Navigator.pop(context, croppedBytes);
      }
    } finally {
      if (mounted) {
        setState(() => _cropping = false);
      }
    }
  }
}

class _CropViewport extends StatelessWidget {
  const _CropViewport({
    required this.image,
    required this.imageBytes,
    required this.offset,
    required this.scale,
    required this.size,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  final ui.Image image;
  final Uint8List imageBytes;
  final Offset offset;
  final double scale;
  final double size;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final baseSize = _coverSize(image, size);

    return GestureDetector(
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoftOf(context),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: AppColors.softShadowOf(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: baseSize.width,
                    height: baseSize.height,
                    child: Image.memory(imageBytes, fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.82),
                    width: 2,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.72),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropMessage extends StatelessWidget {
  const _CropMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tintOf(context, color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tintOf(context, color)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subduedOf(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<ui.Image> _decodeUiImage(Uint8List bytes) {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromList(bytes, completer.complete);

  return completer.future;
}

Future<Uint8List> _renderCrop({
  required ui.Image image,
  required Offset offset,
  required double scale,
  required double viewportSize,
}) async {
  const outputSize = _AvatarCropDialogState._outputSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high;
  final baseSize = _coverSize(image, viewportSize);
  final scaledWidth = baseSize.width * scale;
  final scaledHeight = baseSize.height * scale;
  final factor = outputSize / viewportSize;
  final topLeft = Offset(
    ((viewportSize - scaledWidth) / 2) + offset.dx,
    ((viewportSize - scaledHeight) / 2) + offset.dy,
  );
  final destination = Rect.fromLTWH(
    topLeft.dx * factor,
    topLeft.dy * factor,
    scaledWidth * factor,
    scaledHeight * factor,
  );

  canvas.drawColor(Colors.transparent, BlendMode.clear);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    destination,
    paint,
  );

  final picture = recorder.endRecording();
  final outputImage = await picture.toImage(outputSize, outputSize);
  final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
  outputImage.dispose();
  picture.dispose();

  return byteData!.buffer.asUint8List();
}

Size _coverSize(ui.Image image, double viewportSize) {
  final aspectRatio = image.width / image.height;

  if (aspectRatio >= 1) {
    return Size(viewportSize * aspectRatio, viewportSize);
  }

  return Size(viewportSize, viewportSize / aspectRatio);
}

Offset _clampOffset({
  required ui.Image image,
  required double viewportSize,
  required Offset offset,
  required double scale,
}) {
  final baseSize = _coverSize(image, viewportSize);
  final scaledWidth = baseSize.width * scale;
  final scaledHeight = baseSize.height * scale;
  final maxDx = math.max(0, (scaledWidth - viewportSize) / 2);
  final maxDy = math.max(0, (scaledHeight - viewportSize) / 2);

  return Offset(
    offset.dx.clamp(-maxDx, maxDx).toDouble(),
    offset.dy.clamp(-maxDy, maxDy).toDouble(),
  );
}
