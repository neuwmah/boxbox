import 'package:flutter/material.dart';

const levelSize = 10;

enum BlockShape { box, triangle, rect }

const box = BlockShape.box;
const triangle = BlockShape.triangle;
const rect = BlockShape.rect;

class Block {
  const Block(this.x, this.y, this.layer, this.color, this.type);
  final int x;
  final int y;
  final int layer;
  final int color;
  final BlockShape type;
}

double massForColor(Color color) {
  return 1.0 + 2.0 * (1.0 - color.computeLuminance());
}

List<Block> levelAt(int level) {
  return levels[(level - 1) % levels.length];
}

const levels = <List<Block>>[
  [
    Block(0, 0, 3, 0xFF000000, box),
    Block(1, 0, 3, 0xFF000000, box),
    Block(2, 0, 2, 0xFFFFE800, box),
    Block(3, 0, 3, 0xFF000000, box),
    Block(4, 0, 3, 0xFF000000, box),
    Block(5, 0, 2, 0xFFFFE800, box),
    Block(6, 0, 3, 0xFF000000, box),
    Block(7, 0, 3, 0xFF000000, box),
    Block(8, 0, 3, 0xFF000000, box),
    Block(9, 0, 3, 0xFF000000, box),
    Block(0, 1, 3, 0xFF000000, box),
    Block(1, 1, 3, 0xFF000000, box),
    Block(2, 1, 2, 0xFFFFE800, box),
    Block(3, 1, 2, 0xFFFFE800, box),
    Block(4, 1, 2, 0xFFFFE800, box),
    Block(5, 1, 2, 0xFFFFE800, box),
    Block(6, 1, 2, 0xFFD38100, box),
    Block(7, 1, 3, 0xFF000000, box),
    Block(8, 1, 3, 0xFF000000, box),
    Block(9, 1, 3, 0xFF000000, box),
    Block(0, 2, 3, 0xFF000000, box),
    Block(1, 2, 3, 0xFF000000, box),
    Block(2, 2, 2, 0xFFFFE800, box),
    Block(3, 2, 2, 0xFFFFE800, box),
    Block(4, 2, 2, 0xFFFFE800, box),
    Block(5, 2, 2, 0xFFFFE800, box),
    Block(8, 2, 3, 0xFF000000, box),
    Block(9, 2, 3, 0xFF000000, box),
    Block(0, 3, 3, 0xFF000000, box),
    Block(1, 3, 2, 0xFFF92F3C, box),
    Block(2, 3, 2, 0xFFFFE800, box),
    Block(3, 3, 2, 0xFFFFE800, box),
    Block(4, 3, 2, 0xFFFFE800, box),
    Block(5, 3, 2, 0xFFF92F3C, box),
    Block(7, 3, 2, 0xFFFFE800, rect),
    Block(8, 3, 2, 0xFFFFE800, box),
    Block(9, 3, 3, 0xFF000000, box),
    Block(1, 4, 2, 0xFFFFE800, box),
    Block(2, 4, 2, 0xFF343341, box),
    Block(3, 4, 2, 0xFFFFE800, box),
    Block(4, 4, 2, 0xFF343341, box),
    Block(5, 4, 2, 0xFFFFE800, box),
    Block(8, 4, 2, 0xFFFFE800, triangle),
    Block(2, 5, 2, 0xFFFFE800, box),
    Block(3, 5, 2, 0xFFFFE800, box),
    Block(4, 5, 2, 0xFFFFE800, box),
    Block(5, 5, 2, 0xFFFFE800, box),
    Block(3, 6, 2, 0xFFFFE800, box),
    Block(5, 6, 2, 0xFFFFE800, box),
    Block(3, 7, 2, 0xFF343341, triangle),
    Block(5, 7, 2, 0xFF343341, triangle),
  ],
];
