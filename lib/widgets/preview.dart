import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:boxbox/game/level.dart';

class LevelPixelArt extends StatelessWidget {
  const LevelPixelArt({
    super.key,
    required this.level,
    this.size = 96,
  });

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sprite = _LevelSprite.parse(levelAt(level));
    final layout = sprite.layout(size);
    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: CustomPaint(
        painter: _LevelPixelPainter(sprite, layout),
      ),
    );
  }
}

class _Cell {
  const _Cell(this.front, this.color, this.type);

  final int front;
  final int color;
  final BlockShape type;
}

class _Layout {
  const _Layout({
    required this.cell,
    required this.width,
    required this.height,
  });

  final double cell;
  final double width;
  final double height;
}

class _LevelSprite {
  const _LevelSprite({
    required this.cells,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final List<_Cell?> cells;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  int get cols => maxX - minX + 1;
  int get rows => maxY - minY + 1;
  bool get isEmpty => maxX < minX;

  static const _shadow = 2.0;

  static int _frontLayer(int layer) {
    final digits = layer.toString();
    if (digits.contains('1')) return 1;
    if (digits.contains('2')) return 2;
    if (digits.contains('3')) return 3;
    return 99;
  }

  static _LevelSprite parse(List<Block> blocks) {
    final cells = List<_Cell?>.filled(levelSize * levelSize, null);

    for (final block in blocks) {
      if ((block.color & 0x00FFFFFF) == 0) continue;
      if (block.x < 0 ||
          block.x >= levelSize ||
          block.y < 0 ||
          block.y >= levelSize) {
        continue;
      }

      final index = block.y * levelSize + block.x;
      final front = _frontLayer(block.layer);
      final current = cells[index];
      if (current == null || front < current.front) {
        cells[index] = _Cell(front, block.color, block.type);
      }
    }

    var minX = levelSize;
    var maxX = -1;
    var minY = levelSize;
    var maxY = -1;
    for (var y = 0; y < levelSize; y++) {
      for (var x = 0; x < levelSize; x++) {
        if (cells[y * levelSize + x] == null) continue;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    return _LevelSprite(
      cells: cells,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  _Layout layout(double maxSide) {
    if (isEmpty) {
      return _Layout(cell: 1, width: maxSide, height: maxSide);
    }
    final avail = maxSide - _shadow;
    final cell = (avail / math.max(cols, rows)).floorToDouble();
    final size = cell < 1 ? 1.0 : cell;
    return _Layout(
      cell: size,
      width: size * cols + _shadow,
      height: size * rows + _shadow,
    );
  }
}

class _LevelPixelPainter extends CustomPainter {
  _LevelPixelPainter(this.sprite, this.layout);

  final _LevelSprite sprite;
  final _Layout layout;

  @override
  void paint(Canvas canvas, Size size) {
    if (sprite.isEmpty) return;

    final cell = layout.cell;
    final fill = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.fill
      ..color = const Color(0x99000000);

    Offset cellOrigin(int x, int y) {
      return Offset(
        (x - sprite.minX) * cell,
        (sprite.maxY - y) * cell,
      );
    }

    for (var y = sprite.minY; y <= sprite.maxY; y++) {
      for (var x = sprite.minX; x <= sprite.maxX; x++) {
        if (sprite.cells[y * levelSize + x] == null) continue;
        final origin = cellOrigin(x, y);
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + _LevelSprite._shadow,
            origin.dy + _LevelSprite._shadow,
            cell,
            cell,
          ),
          shadow,
        );
      }
    }

    for (var y = sprite.minY; y <= sprite.maxY; y++) {
      for (var x = sprite.minX; x <= sprite.maxX; x++) {
        final data = sprite.cells[y * levelSize + x];
        if (data == null) continue;
        final origin = cellOrigin(x, y);
        fill.color = Color(data.color);
        final rect = Rect.fromLTWH(origin.dx, origin.dy, cell, cell);
        if (data.type == BlockShape.triangle) {
          canvas.drawPath(
            Path()
              ..moveTo(rect.center.dx, rect.top)
              ..lineTo(rect.right, rect.bottom)
              ..lineTo(rect.left, rect.bottom)
              ..close(),
            fill,
          );
        } else {
          canvas.drawRect(rect, fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPixelPainter oldDelegate) {
    return oldDelegate.sprite != sprite || oldDelegate.layout != layout;
  }
}
