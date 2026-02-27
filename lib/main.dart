import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '将棋符号トレーニング',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const ShogiTrainingPage(),
    );
  }
}

class ShogiTrainingPage extends StatefulWidget {
  const ShogiTrainingPage({super.key});

  @override
  State<ShogiTrainingPage> createState() => _ShogiTrainingPageState();
}

class _ShogiTrainingPageState extends State<ShogiTrainingPage> {
  final Random _random = Random();

  int _targetCol = 1; // 1-9
  int _targetRow = 1; // 1-9

  final List<bool> _recentResults = []; // 直近の結果（最大10件）

  int? _clickedCol;
  int? _clickedRow;
  bool? _isCorrect;

  bool _isSente = true; // true=先手視点, false=後手視点
  bool _advancedMode = false; // true=上級者モード（目盛り非表示）

  static const List<String> _kanjiRows = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _targetCol = _random.nextInt(9) + 1;
      _targetRow = _random.nextInt(9) + 1;
      _clickedCol = null;
      _clickedRow = null;
      _isCorrect = null;
    });
  }

  String get _questionText => '$_targetCol${_kanjiRows[_targetRow - 1]}';

  void _onCellTap(int col, int row) {
    if (_isCorrect != null) return;

    final correct = col == _targetCol && row == _targetRow;
    setState(() {
      _clickedCol = col;
      _clickedRow = row;
      _isCorrect = correct;
      _recentResults.add(correct);
      if (_recentResults.length > 10) _recentResults.removeAt(0);
    });

    Future.delayed(Duration(milliseconds: correct ? 380 : 600), () {
      if (mounted) _nextQuestion();
    });
  }

  // 表示インデックス(0-8)から実際の列番号(1-9)を取得
  int _colFromDisplayIdx(int idx) => _isSente ? 9 - idx : idx + 1;

  // 表示インデックス(0-8)から実際の行番号(1-9)を取得
  int _rowFromDisplayIdx(int idx) => _isSente ? idx + 1 : 9 - idx;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('将棋符号トレーニング'),
        backgroundColor: Colors.brown[300],
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Switch(
                value: !_isSente,
                onChanged: (v) => setState(() => _isSente = !v),
                activeThumbColor: Colors.white,
              ),
              const Text('後手'),
              const SizedBox(width: 8),
              Switch(
                value: _advancedMode,
                onChanged: (v) => setState(() => _advancedMode = v),
                activeThumbColor: Colors.white,
              ),
              const Text('上級者'),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 将棋盤
          Expanded(
            child: Center(child: _buildBoard()),
          ),
          const SizedBox(height: 16),
          // 出題（正解→緑、不正解→赤）
          Text(
            _questionText,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: _isCorrect == null
                  ? Colors.black
                  : (_isCorrect! ? Colors.green : Colors.red),
            ),
          ),
          const SizedBox(height: 8),
          // 直近10回の正解割合
          _buildRecentResultBar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecentResultBar() {
    if (_recentResults.isEmpty) {
      return const Text('直近10回: -', style: TextStyle(fontSize: 14, color: Colors.grey));
    }
    final recentCorrect = _recentResults.where((r) => r).length;
    final pct = (recentCorrect / _recentResults.length * 100).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('直近${_recentResults.length}回: $recentCorrect/${_recentResults.length} ($pct%)',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        ...List.generate(10, (i) {
          // 古い順に表示。_recentResultsは最大10件
          final offset = 10 - _recentResults.length;
          final hasResult = i >= offset;
          final result = hasResult ? _recentResults[i - offset] : false;
          return Container(
            width: 16, height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: hasResult
                  ? (result ? Colors.green : Colors.red)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 実際の将棋盤のマス比率: 縦3.86cm × 横3.52cm
        const cellAspect = 3.52 / 3.86; // width / height
        const labelRatio = 0.7; // ラベル幅 = cellWidth * labelRatio（常に確保）

        // 盤面サイズはラベル表示・非表示に関わらず常に同じ計算
        // 幅方向: 9*cellW + labelRatio*cellW = maxW
        final cellWFromWidth = constraints.maxWidth / (9 + labelRatio);
        // 高さ方向: labelRatio*cellW + 9*(cellW/cellAspect) = maxH
        final cellWFromHeight = constraints.maxHeight / (labelRatio + 9 / cellAspect);
        final cellWidth = cellWFromWidth < cellWFromHeight ? cellWFromWidth : cellWFromHeight;
        final cellHeight = cellWidth / cellAspect;
        final labelSize = cellWidth * labelRatio;

        final totalWidth = 9 * cellWidth + labelSize;
        final totalHeight = labelSize + 9 * cellHeight;

        return SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Column(
            children: [
              // 列番号ヘッダー（領域は常に確保、テキストのみ出し分け）
              SizedBox(
                height: labelSize,
                child: Row(
                  children: [
                    ...List.generate(9, (dColIdx) {
                      final col = _colFromDisplayIdx(dColIdx);
                      return SizedBox(
                        width: cellWidth,
                        child: _advancedMode
                            ? null
                            : Center(
                                child: Text(
                                  '$col',
                                  style: TextStyle(
                                    fontSize: labelSize * 0.55,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      );
                    }),
                    SizedBox(width: labelSize),
                  ],
                ),
              ),
              // 盤面
              ...List.generate(9, (dRowIdx) {
                final row = _rowFromDisplayIdx(dRowIdx);
                return SizedBox(
                  height: cellHeight,
                  child: Row(
                    children: [
                      // マス
                      ...List.generate(9, (dColIdx) {
                        final col = _colFromDisplayIdx(dColIdx);
                        final isTarget = col == _targetCol && row == _targetRow;
                        final isClicked = col == _clickedCol && row == _clickedRow;

                        Color cellColor = const Color(0xFFE8C880);
                        if (_isCorrect != null) {
                          if (isTarget) {
                            cellColor = Colors.green[400]!;
                          } else if (isClicked && !_isCorrect!) {
                            cellColor = Colors.red[400]!;
                          }
                        }

                        return GestureDetector(
                          onTap: () => _onCellTap(col, row),
                          child: Container(
                            width: cellWidth,
                            height: cellHeight,
                            decoration: BoxDecoration(
                              color: cellColor,
                              border: Border.all(
                                color: Colors.brown[800]!,
                                width: 0.8,
                              ),
                            ),
                          ),
                        );
                      }),
                      // 行ラベル（右側、領域は常に確保、テキストのみ出し分け）
                      SizedBox(
                        width: labelSize,
                        child: _advancedMode
                            ? null
                            : Center(
                                child: Text(
                                  _kanjiRows[row - 1],
                                  style: TextStyle(
                                    fontSize: labelSize * 0.55,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
