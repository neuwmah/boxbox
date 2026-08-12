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
    Block(0, 0, 23, 0xFF000000, box),
    Block(1, 0, 23, 0xFF000000, box),
    Block(2, 0, 3, 0xFFFFE800, box),
    Block(3, 0, 23, 0xFF000000, box),
    Block(4, 0, 23, 0xFF000000, box),
    Block(5, 0, 3, 0xFFFFE800, box),
    Block(6, 0, 23, 0xFF000000, box),
    Block(7, 0, 23, 0xFF000000, box),
    Block(8, 0, 23, 0xFF000000, box),
    Block(9, 0, 23, 0xFF000000, box),
    Block(0, 1, 23, 0xFF000000, box),
    Block(1, 1, 23, 0xFF000000, box),
    Block(2, 1, 3, 0xFFFFE800, box),
    Block(3, 1, 3, 0xFFFFE800, box),
    Block(4, 1, 3, 0xFFFFE800, box),
    Block(5, 1, 3, 0xFFFFE800, box),
    Block(6, 1, 3, 0xFFD38100, box),
    Block(7, 1, 23, 0xFF000000, box),
    Block(8, 1, 23, 0xFF000000, box),
    Block(9, 1, 23, 0xFF000000, box),
    Block(0, 2, 23, 0xFF000000, box),
    Block(1, 2, 23, 0xFF000000, box),
    Block(2, 2, 3, 0xFFFFE800, box),
    Block(3, 2, 3, 0xFFFFE800, box),
    Block(4, 2, 3, 0xFFFFE800, box),
    Block(5, 2, 3, 0xFFFFE800, box),
    Block(8, 2, 23, 0xFF000000, box),
    Block(9, 2, 23, 0xFF000000, box),
    Block(0, 3, 23, 0xFF000000, box),
    Block(1, 3, 3, 0xFFF92F3C, box),
    Block(2, 3, 3, 0xFFFFE800, box),
    Block(3, 3, 3, 0xFFFFE800, box),
    Block(4, 3, 3, 0xFFFFE800, box),
    Block(5, 3, 3, 0xFFF92F3C, box),
    Block(7, 3, 3, 0xFFFFE800, rect),
    Block(8, 3, 3, 0xFFFFE800, box),
    Block(9, 3, 23, 0xFF000000, box),
    Block(1, 4, 3, 0xFFFFE800, box),
    Block(2, 4, 3, 0xFF343341, box),
    Block(3, 4, 3, 0xFFFFE800, box),
    Block(4, 4, 3, 0xFF343341, box),
    Block(5, 4, 3, 0xFFFFE800, box),
    Block(8, 4, 3, 0xFFFFE800, triangle),
    Block(2, 5, 3, 0xFFFFE800, box),
    Block(3, 5, 3, 0xFFFFE800, box),
    Block(4, 5, 3, 0xFFFFE800, box),
    Block(5, 5, 3, 0xFFFFE800, box),
    Block(3, 6, 3, 0xFFFFE800, box),
    Block(5, 6, 3, 0xFFFFE800, box),
    Block(3, 7, 3, 0xFF343341, triangle),
    Block(5, 7, 3, 0xFF343341, triangle),
  ],
];
