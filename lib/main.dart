import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const Game2048App());

// ===== 游戏配置 =====
class GameConfig {
  static int maxUndoSteps = 3; // 最大撤销步数
  static int hintDelaySeconds = 60; // 提示延迟时间（秒）
  static String theme = 'classic'; // 当前主题
  static int gridSize = 4; // 网格大小（4x4）
  static String gameMode = 'endless'; // 游戏模式：'endless'（无尽）或'reach2048'（达到2048）
}

// ===== 主题系统 =====
class GameTheme {
  final String name; // 主题名称
  final Color backgroundColor; // 背景颜色
  final Color boardColor; // 棋盘颜色
  final Color emptyTileColor; // 空格颜色
  final Color textColor; // 文字颜色
  final Color buttonColor; // 按钮颜色

  const GameTheme({
    required this.name,
    required this.backgroundColor,
    required this.boardColor,
    required this.emptyTileColor,
    required this.textColor,
    required this.buttonColor,
  });

  // 根据数值获取对应方块颜色
  Color getTileColor(int value) {
    final Map<int, Color> colors;
    if (name == 'dark') {
      colors = {
        2: const Color(0xFF533483),
        4: const Color(0xFF6247AA),
        8: const Color(0xFF7F5AF0),
        16: const Color(0xFF2CB67D),
        32: const Color(0xFF16C79A),
        64: const Color(0xFF19D3DA),
        128: const Color(0xFFFD8A8A),
        256: const Color(0xFFF68989),
        512: const Color(0xFFED6A5A),
        1024: const Color(0xFFFF9770),
        2048: const Color(0xFFFFAA00),
        4096: const Color(0xFFFF6B9D),
      };
    } else if (name == 'candy') {
      colors = {
        2: const Color(0xFFFFE4E1),
        4: const Color(0xFFFFB6DB),
        8: const Color(0xFFFF69B4),
        16: const Color(0xFFFF1493),
        32: const Color(0xFFBA55D3),
        64: const Color(0xFF9370DB),
        128: const Color(0xFF87CEEB),
        256: const Color(0xFF00CED1),
        512: const Color(0xFF48D1CC),
        1024: const Color(0xFF7FFFD4),
        2048: const Color(0xFF00FA9A),
        4096: const Color(0xFFFFD700),
      };
    } else {
      colors = {
        2: const Color(0xFFEEE4DA),
        4: const Color(0xFFEDE0C8),
        8: const Color(0xFFF2B179),
        16: const Color(0xFFF59563),
        32: const Color(0xFFF67C5F),
        64: const Color(0xFFF65E3B),
        128: const Color(0xFFEDCF72),
        256: const Color(0xFFEDCC61),
        512: const Color(0xFFEDC850),
        1024: const Color(0xFFE6B800),
        2048: const Color(0xFFFFD700),
        4096: const Color(0xFF00BFFF),
      };
    }
    return colors[value] ?? const Color(0xFF000000);
  }

  // 经典主题
  static final GameTheme classic = GameTheme(
    name: 'classic',
    backgroundColor: const Color(0xFFFAF8EF),
    boardColor: const Color(0xFFBBADA0),
    emptyTileColor: const Color(0xFFCDC1B4),
    textColor: const Color(0xFF776E65),
    buttonColor: const Color(0xFF8F7A66),
  );

  // 深色主题
  static final GameTheme dark = GameTheme(
    name: 'dark',
    backgroundColor: const Color(0xFF1A1A2E),
    boardColor: const Color(0xFF16213E),
    emptyTileColor: const Color(0xFF0F3460),
    textColor: const Color(0xFFEEEEEE),
    buttonColor: const Color(0xFF7F5AF0),
  );

  // 糖果主题
  static final GameTheme candy = GameTheme(
    name: 'candy',
    backgroundColor: const Color(0xFFFFF0F5),
    boardColor: const Color(0xFFFFB6C1),
    emptyTileColor: const Color(0xFFFFDAE7),
    textColor: const Color(0xFFFF1493),
    buttonColor: const Color(0xFFFF69B4),
  );

  // 根据名称获取主题
  static GameTheme get(String name) {
    switch (name) {
      case 'dark':
        return dark;
      case 'candy':
        return candy;
      default:
        return classic;
    }
  }
}

// ===== 国际化管理 =====
class AppLocale {
  static bool isChinese = true; // 是否为中文模式
  static String get title => isChinese ? "练手2048" : "Practice 2048"; // 标题
  static String get start => isChinese ? "新游戏" : "New Game"; // 开始游戏
  static String get continueGame => isChinese ? "继续游戏" : "Continue"; // 继续游戏
  static String get exit => isChinese ? "退出游戏" : "Exit"; // 退出
  static String get score => isChinese ? "分数" : "Score"; // 分数
  static String get best => isChinese ? "最高分" : "Best"; // 最高分
  static String get gameOver => isChinese ? "游戏结束" : "Game Over"; // 游戏结束
  static String get victory => isChinese ? "胜利！" : "Victory!"; // 胜利
  static String get finalScore => isChinese ? "最终得分" : "Final Score"; // 最终得分
  static String get again => isChinese ? "再来一把" : "Play Again"; // 再来一局
  static String get back => isChinese ? "返回主界面" : "Menu"; // 返回菜单
  static String get settings => isChinese ? "设置" : "Settings"; // 设置
  static String get bgm => isChinese ? "背景音乐" : "BGM"; // 背景音乐
  static String get sfx => isChinese ? "音效" : "SFX"; // 音效
  static String get lang => isChinese ? "English Mode" : "中文模式"; // 语言切换
  static String get undo => isChinese ? "撤销" : "Undo"; // 撤销
  static String get theme => isChinese ? "主题" : "Theme"; // 主题
  static String get mode => isChinese ? "游戏模式" : "Mode"; // 模式
  static String get endless => isChinese ? "无尽模式" : "Endless"; // 无尽模式
  static String get reach2048 =>
      isChinese ? "达到2048" : "Reach 2048"; // 达到2048模式
  static String get gridSize => isChinese ? "网格大小" : "Grid Size"; // 网格大小
  static String get hintDelay => isChinese ? "提示延迟(秒)" : "Hint Delay"; // 提示延迟
  static String get maxUndos => isChinese ? "最大撤销次数" : "Max Undos"; // 最大撤销次数
  static String get restart => isChinese ? "重新开始" : "Restart"; // 重新开始
  static String get confirmRestart =>
      isChinese ? "确认重新开始？当前进度将丢失" : "Restart? Progress will be lost"; // 确认重新开始
  static String get yes => isChinese ? "确定" : "Yes"; // 确定
  static String get no => isChinese ? "取消" : "No"; // 取消
  static String get combo => isChinese ? "连击" : "Combo"; // 连击
  static String get stats => isChinese ? "统计" : "Stats"; // 统计
  static String get totalGames => isChinese ? "总局数" : "Total Games"; // 总局数
  static String get totalMoves => isChinese ? "总移动" : "Total Moves"; // 总移动步数
}

// ===== 游戏状态快照（用于撤销功能） =====
class GameSnapshot {
  final List<TileModel> tiles; // 方块列表
  final int score; // 分数
  final int nextId; // 下一个方块ID

  GameSnapshot({
    required this.tiles,
    required this.score,
    required this.nextId,
  });

  // 复制快照
  GameSnapshot copy() {
    return GameSnapshot(
      tiles: tiles
          .map((t) => TileModel(id: t.id, value: t.value, x: t.x, y: t.y))
          .toList(),
      score: score,
      nextId: nextId,
    );
  }
}

// ===== 音频管理器（解决语法错误与混音中断问题） =====
class AudioManager {
  // 核心：使用两个完全独立的播放器实例
  static final AudioPlayer _bgmPlayer = AudioPlayer(); // 背景音乐播放器
  static final AudioPlayer _sfxPlayer = AudioPlayer(); // 音效播放器

  static double bgmVolume = 0.5; // 背景音乐音量
  static double sfxVolume = 0.8; // 音效音量
  static bool isBgmEnabled = true; // 背景音乐是否启用

  // 初始化音频管理器
  static Future<void> init() async {
    // 关键修复1：为BGM播放器设置专用的音频上下文（音乐模式）
    final AudioContext bgmContext = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media, // 使用media类型而不是game
        audioFocus: AndroidAudioFocus.none, // 不请求独占焦点，允许混音
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback, // iOS使用playback以获得更好的背景播放支持
        options: {AVAudioSessionOptions.mixWithOthers}, // 允许与其他音频混音
      ),
    );

    // 关键修复2：为音效播放器设置专用的音频上下文（音效模式）
    final AudioContext sfxContext = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification, // 音效类型
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none, // 不请求焦点，避免打断BGM
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient, // iOS环境音模式
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );

    // 为每个播放器单独设置音频上下文
    await _bgmPlayer.setAudioContext(bgmContext);
    await _sfxPlayer.setAudioContext(sfxContext);

    // 修复3：BGM设置为循环模式
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    // 修复4：SFX使用stop模式，防止在某些设备上释放资源过猛导致BGM停止
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    // 修复5：设置BGM播放器为低延迟模式以获得更好的播放连续性
    await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  }

  // 播放背景音乐
  static void playBGM() async {
    if (!isBgmEnabled) return;
    try {
      await _bgmPlayer.setVolume(bgmVolume);
      // 使用Source方式播放，确保路径匹配
      await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
    } catch (e) {
      debugPrint("BGM播放错误: $e");
    }
  }

  // 切换背景音乐开关
  static void toggleBGM() async {
    isBgmEnabled = !isBgmEnabled;
    if (isBgmEnabled) {
      playBGM();
    } else {
      await _bgmPlayer.stop(); // 仅操作BGM播放器，不干扰音效
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBgmEnabled', isBgmEnabled);
  }

  // 内部音效播放逻辑
  static void _playSfx(String path) async {
    if (sfxVolume > 0) {
      try {
        // 设置音效播放器音量
        await _sfxPlayer.setVolume(sfxVolume);
        // 关键：使用lowLatency模式，告诉Android这是低延迟混音音效
        await _sfxPlayer.play(AssetSource(path), mode: PlayerMode.lowLatency);
      } catch (e) {
        debugPrint("音效播放错误: $e");
      }
    }
  }

  // 音效触发接口
  static void playStartSfx() => _playSfx('audio/gamestart.mp3'); // 游戏开始音效
  static void playMoveSfx() => _playSfx('audio/move.mp3'); // 移动音效
  static void playMergeSfx() => _playSfx('audio/merge.mp3'); // 合并音效
  static void playGameOverSfx() => _playSfx('audio/gameover.mp3'); // 游戏结束音效

  // 更新背景音乐音量
  static void updateBgmVolume(double v) {
    bgmVolume = v;
    if (isBgmEnabled) _bgmPlayer.setVolume(v);
  }
}

// ===== 方块模型 =====
class TileModel {
  final int id; // 唯一标识
  int value; // 数值
  int x, y; // 坐标位置
  bool merged; // 是否已合并

  TileModel({
    required this.id,
    required this.value,
    required this.x,
    required this.y,
    this.merged = false,
  });
}

// ===== 游戏应用入口 =====
class Game2048App extends StatelessWidget {
  const Game2048App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const GamePage(),
    );
  }
}

// ===== 游戏页面 =====
class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<TileModel> tiles = []; // 方块列表
  int nextId = 0, score = 0, highScore = 0; // 下一个ID、当前分数、最高分
  bool isGameOver = false, isGameStart = true, isAnimating = false; // 游戏状态标志
  bool hasSavedGame = false; // 是否有存档
  bool isVictory = false; // 是否胜利

  // 撤销系统
  List<GameSnapshot> history = []; // 历史记录
  int undosLeft = GameConfig.maxUndoSteps; // 剩余撤销次数

  // 智能提示系统
  Timer? hintTimer; // 提示定时器
  Direction? suggestedDirection; // 建议方向

  // 连击系统
  int currentCombo = 0; // 当前连击数
  int maxCombo = 0; // 最大连击数

  // 统计系统
  int totalGames = 0; // 总局数
  int totalMoves = 0; // 总移动步数

  // 主题
  late GameTheme currentTheme; // 当前主题

  late double boardSize; // 棋盘大小
  final double margin = 8.0; // 间距
  late double tileSize; // 方块大小

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      AudioManager.init().then((_) {
        AudioManager.playBGM();
      });
    });
  }

  // 更新棋盘大小
  void _updateBoardSize() {
    // 使用WidgetsBinding获取准确的屏幕尺寸
    final screenWidth =
        WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;
    boardSize = min(screenWidth - 40, 380.0);
    tileSize =
        (boardSize - (margin * (GameConfig.gridSize + 1))) /
        GameConfig.gridSize;
  }

  @override
  void dispose() {
    hintTimer?.cancel();
    super.dispose();
  }

  // ===== 存档与设置逻辑 =====

  // 保存游戏进度
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    String tilesData = tiles.map((t) => "${t.x},${t.y},${t.value}").join(";");
    await prefs.setString('saved_tiles', tilesData);
    await prefs.setInt('saved_score', score);
    await prefs.setBool('has_saved_game', true);
    setState(() => hasSavedGame = true);
  }

  // 加载游戏进度
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    String? tilesData = prefs.getString('saved_tiles');
    if (tilesData != null && tilesData.isNotEmpty) {
      List<TileModel> loadedTiles = [];
      int idCounter = 0;
      for (var tileStr in tilesData.split(";")) {
        var parts = tileStr.split(",");
        loadedTiles.add(
          TileModel(
            id: idCounter++,
            x: int.parse(parts[0]),
            y: int.parse(parts[1]),
            value: int.parse(parts[2]),
          ),
        );
      }
      setState(() {
        tiles = loadedTiles;
        score = prefs.getInt('saved_score') ?? 0;
        isGameStart = false;
        isGameOver = false;
        nextId = idCounter;
      });
      AudioManager.playStartSfx();
    }
  }

  // 清除游戏进度
  Future<void> _clearGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_saved_game', false);
    await prefs.remove('saved_tiles');
    await prefs.remove('saved_score');
    setState(() => hasSavedGame = false);
  }

  // ===== 辅助功能 =====

  // 保存状态到历史记录
  void _saveStateToHistory() {
    if (history.length >= GameConfig.maxUndoSteps) {
      history.removeAt(0);
    }
    history.add(
      GameSnapshot(
        tiles: tiles
            .map((t) => TileModel(id: t.id, value: t.value, x: t.x, y: t.y))
            .toList(),
        score: score,
        nextId: nextId,
      ),
    );
  }

  // 执行撤销
  void performUndo() {
    if (history.isEmpty || undosLeft <= 0) return;
    final snapshot = history.removeLast();
    setState(() {
      tiles = snapshot.tiles;
      score = snapshot.score;
      nextId = snapshot.nextId;
      undosLeft--;
      currentCombo = 0;
    });
    _resetHintTimer();
  }

  // 重置提示定时器
  void _resetHintTimer() {
    hintTimer?.cancel();
    suggestedDirection = null;
    if (GameConfig.hintDelaySeconds > 0 && !isGameOver && !isGameStart) {
      hintTimer = Timer(Duration(seconds: GameConfig.hintDelaySeconds), () {
        if (!isGameOver && !isGameStart) {
          _calculateHint();
        }
      });
    }
  }

  // 计算提示方向
  void _calculateHint() {
    // 简单的AI：尝试每个方向，选择得分最高的
    Direction? best;
    int bestScore = -1;

    for (var dir in Direction.values) {
      final simScore = _simulateMove(dir);
      if (simScore > bestScore) {
        bestScore = simScore;
        best = dir;
      }
    }

    if (best != null && mounted) {
      setState(() => suggestedDirection = best);
    }
  }

  // 模拟移动并返回可能的得分变化
  int _simulateMove(Direction dir) {
    int potentialScore = 0;
    List<bool> used = List.filled(tiles.length, false);

    for (int line = 0; line < GameConfig.gridSize; line++) {
      final lineTiles = _getLineTiles(line, dir);
      int i = 0;
      while (i < lineTiles.length) {
        if (i + 1 < lineTiles.length &&
            lineTiles[i + 1].value == lineTiles[i].value) {
          potentialScore += lineTiles[i].value * 2;
          i += 2;
        } else {
          i += 1;
        }
      }
    }
    return potentialScore;
  }

  // 检查是否胜利
  void _checkVictory() {
    if (GameConfig.gameMode == 'reach2048') {
      for (var tile in tiles) {
        if (tile.value >= 2048 && !isVictory) {
          setState(() => isVictory = true);
          _showVictoryDialog();
          break;
        }
      }
    }
  }

  // 显示胜利对话框
  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        title: Text(
          AppLocale.victory,
          style: TextStyle(color: currentTheme.textColor),
        ),
        content: Text(
          "${AppLocale.finalScore}: $score",
          style: TextStyle(color: currentTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isVictory = false);
            },
            child: Text(AppLocale.again),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearGameProgress(); // 清除存档
              setState(() {
                isVictory = false;
                isGameStart = true;
              });
            },
            child: Text(AppLocale.back),
          ),
        ],
      ),
    );
  }

  // 显示重新开始确认对话框
  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        title: Text(
          AppLocale.restart,
          style: TextStyle(color: currentTheme.textColor),
        ),
        content: Text(
          AppLocale.confirmRestart,
          style: TextStyle(color: currentTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocale.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              initGame();
            },
            child: Text(AppLocale.yes),
          ),
        ],
      ),
    );
  }

  // ===== 设置加载与保存 =====

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
      AudioManager.bgmVolume = prefs.getDouble('bgmVol') ?? 0.5;
      AudioManager.sfxVolume = prefs.getDouble('sfxVol') ?? 0.8;
      AudioManager.isBgmEnabled = prefs.getBool('isBgmEnabled') ?? true;
      AppLocale.isChinese = prefs.getBool('isChinese') ?? true;
      hasSavedGame = prefs.getBool('has_saved_game') ?? false;

      // 加载新配置
      GameConfig.maxUndoSteps = prefs.getInt('maxUndoSteps') ?? 3;
      GameConfig.hintDelaySeconds = prefs.getInt('hintDelaySeconds') ?? 60;
      GameConfig.theme = prefs.getString('theme') ?? 'classic';
      GameConfig.gridSize = prefs.getInt('gridSize') ?? 4;
      GameConfig.gameMode = prefs.getString('gameMode') ?? 'endless';

      totalGames = prefs.getInt('totalGames') ?? 0;
      totalMoves = prefs.getInt('totalMoves') ?? 0;
      maxCombo = prefs.getInt('maxCombo') ?? 0;

      currentTheme = GameTheme.get(GameConfig.theme);
      undosLeft = GameConfig.maxUndoSteps;

      // 更新网格大小相关计算
      _updateBoardSize();
    });
  }

  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('bgmVol', AudioManager.bgmVolume);
    prefs.setDouble('sfxVol', AudioManager.sfxVolume);
    prefs.setBool('isChinese', AppLocale.isChinese);
    prefs.setBool('isBgmEnabled', AudioManager.isBgmEnabled);
    prefs.setInt('maxUndoSteps', GameConfig.maxUndoSteps);
    prefs.setInt('hintDelaySeconds', GameConfig.hintDelaySeconds);
    prefs.setString('theme', GameConfig.theme);
    prefs.setInt('gridSize', GameConfig.gridSize);
    prefs.setString('gameMode', GameConfig.gameMode);
    prefs.setInt('totalGames', totalGames);
    prefs.setInt('totalMoves', totalMoves);
    prefs.setInt('maxCombo', maxCombo);
  }

  // 初始化游戏
  void initGame() {
    _clearGameProgress();
    setState(() {
      tiles = [];
      score = 0;
      nextId = 0;
      isGameOver = false;
      isGameStart = false;
      isVictory = false;
      history.clear();
      undosLeft = GameConfig.maxUndoSteps;
      currentCombo = 0;
      _addNewTile();
      _addNewTile();
    });
    totalGames++;
    _saveSettings();
    _resetHintTimer();
    AudioManager.playStartSfx();
  }

  // 添加新方块
  void _addNewTile() {
    List<Point<int>> occupied = tiles.map((e) => Point(e.x, e.y)).toList();
    List<Point<int>> empty = [];
    for (int r = 0; r < GameConfig.gridSize; r++) {
      for (int c = 0; c < GameConfig.gridSize; c++) {
        if (!occupied.contains(Point(r, c))) empty.add(Point(r, c));
      }
    }
    if (empty.isNotEmpty) {
      final p = empty[Random().nextInt(empty.length)];
      tiles.add(
        TileModel(
          id: nextId++,
          value: Random().nextInt(10) == 0 ? 4 : 2,
          x: p.x,
          y: p.y,
        ),
      );
    }
  }

  // 移动操作
  void move(Direction dir) {
    if (isGameOver || isGameStart || isAnimating || isVictory) return;

    // 保存状态以支持撤销
    _saveStateToHistory();

    bool moved = false;
    bool hasMerged = false;
    for (var t in tiles) t.merged = false;
    List<TileModel> toRemove = [];

    for (int line = 0; line < GameConfig.gridSize; line++) {
      final lineTiles = _getLineTiles(line, dir);
      final newLine = <TileModel>[];
      int i = 0;
      while (i < lineTiles.length) {
        final current = lineTiles[i];
        if (i + 1 < lineTiles.length &&
            lineTiles[i + 1].value == current.value) {
          final moving = lineTiles[i + 1];
          moving.value *= 2;
          moving.merged = true;
          score += moving.value;
          toRemove.add(current);
          newLine.add(moving);
          moved = true;
          hasMerged = true;
          i += 2;
        } else {
          newLine.add(current);
          i += 1;
        }
      }
      for (int pos = 0; pos < newLine.length; pos++) {
        final t = newLine[pos];
        final p = _positionForLine(line, pos, dir);
        if (t.x != p.x || t.y != p.y) moved = true;
        t.x = p.x;
        t.y = p.y;
      }
    }

    if (moved) {
      // 更新连击
      if (hasMerged) {
        currentCombo++;
        if (currentCombo > maxCombo) {
          maxCombo = currentCombo;
          _saveSettings();
        }
        AudioManager.playMergeSfx();
      } else {
        currentCombo = 0;
        AudioManager.playMoveSfx();
      }

      tiles.removeWhere((t) => toRemove.contains(t));

      if (score > highScore) {
        highScore = score;
        SharedPreferences.getInstance().then(
          (p) => p.setInt('highScore', score),
        );
      }

      totalMoves++;
      setState(() => isAnimating = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() {
          _addNewTile();
          isAnimating = false;
        });
        _checkVictory();
        _checkGameOver();
        _saveGameProgress(); // 自动保存
        _resetHintTimer();
      });
    } else {
      // 移动失败，恢复撤销次数
      if (history.isNotEmpty) history.removeLast();
    }
  }

  // 获取某一行/列的方块
  List<TileModel> _getLineTiles(int line, Direction dir) {
    if (dir == Direction.left || dir == Direction.right) {
      final rowTiles = tiles.where((t) => t.x == line).toList();
      rowTiles.sort(
        (a, b) =>
            dir == Direction.left ? a.y.compareTo(b.y) : b.y.compareTo(a.y),
      );
      return rowTiles;
    }
    final colTiles = tiles.where((t) => t.y == line).toList();
    colTiles.sort(
      (a, b) => dir == Direction.up ? a.x.compareTo(b.x) : b.x.compareTo(a.x),
    );
    return colTiles;
  }

  // 计算方块在指定方向上的目标位置
  Point<int> _positionForLine(int line, int pos, Direction dir) {
    final maxPos = GameConfig.gridSize - 1;
    switch (dir) {
      case Direction.left:
        return Point(line, pos);
      case Direction.right:
        return Point(line, maxPos - pos);
      case Direction.up:
        return Point(pos, line);
      case Direction.down:
        return Point(maxPos - pos, line);
    }
  }

  // 检查游戏是否结束
  void _checkGameOver() {
    List<Point<int>> occupied = tiles.map((e) => Point(e.x, e.y)).toList();
    final maxTiles = GameConfig.gridSize * GameConfig.gridSize;
    if (occupied.length < maxTiles) return;
    bool canMove = false;
    for (var tile in tiles) {
      final neighbors = [
        Point(tile.x + 1, tile.y),
        Point(tile.x - 1, tile.y),
        Point(tile.x, tile.y + 1),
        Point(tile.x, tile.y - 1),
      ];
      for (var p in neighbors) {
        if (p.x >= 0 &&
            p.x < GameConfig.gridSize &&
            p.y >= 0 &&
            p.y < GameConfig.gridSize) {
          final neighborTile = tiles.firstWhere(
            (t) => t.x == p.x && t.y == p.y,
          );
          if (neighborTile.value == tile.value) {
            canMove = true;
            break;
          }
        }
      }
      if (canMove) break;
    }
    if (!canMove) {
      setState(() => isGameOver = true);
      AudioManager.playGameOverSfx();
      _clearGameProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildPlayArea(),
              ],
            ),
          ),
          if (suggestedDirection != null && !isGameStart && !isGameOver)
            _buildHintArrow(),
          if (isGameStart) _buildMainMenu(),
          if (isGameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  // ===== UI构建 =====

  // 构建提示箭头
  Widget _buildHintArrow() {
    if (suggestedDirection == null) return const SizedBox.shrink();

    IconData icon;
    switch (suggestedDirection!) {
      case Direction.up:
        icon = Icons.arrow_upward;
        break;
      case Direction.down:
        icon = Icons.arrow_downward;
        break;
      case Direction.left:
        icon = Icons.arrow_back;
        break;
      case Direction.right:
        icon = Icons.arrow_forward;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1,
      left: MediaQuery.of(context).size.width / 2 - 30,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Icon(
              icon,
              size: 60,
              color: currentTheme.buttonColor.withValues(alpha: 0.6),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() {});
            });
          }
        },
      ),
    );
  }

  // 构建主菜单
  Widget _buildMainMenu() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: currentTheme.backgroundColor,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocale.title,
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                // 最高分显示
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: currentTheme.boardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocale.best,
                        style: TextStyle(
                          color: currentTheme.emptyTileColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$highScore",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _menuButton(AppLocale.start, initGame),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSavedGame
                        ? const Color(0xFF8F7A66)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(200, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: hasSavedGame ? _loadGameProgress : null,
                  child: Text(
                    AppLocale.continueGame,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _menuButton(AppLocale.exit, () => SystemNavigator.pop()),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                size: 30,
                color: Color(0xFF776E65),
              ),
              onPressed: _showSettingsDialog,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Text(
              "Made by VignaChu\n2026-02-10",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Color(0x66776E65),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: currentTheme.backgroundColor,
          title: Text(
            AppLocale.settings,
            style: TextStyle(color: currentTheme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sliderRow(AppLocale.bgm, AudioManager.bgmVolume, (v) {
                  setDialogState(() => AudioManager.updateBgmVolume(v));
                  setState(() {});
                }),
                _sliderRow(AppLocale.sfx, AudioManager.sfxVolume, (v) {
                  setDialogState(() => AudioManager.sfxVolume = v);
                  setState(() {});
                }),
                const Divider(),
                // 语言切换
                ListTile(
                  title: Text(
                    AppLocale.lang,
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  trailing: Icon(Icons.language, color: currentTheme.textColor),
                  onTap: () {
                    setDialogState(
                      () => AppLocale.isChinese = !AppLocale.isChinese,
                    );
                    setState(() {});
                    _saveSettings();
                  },
                ),
                // 主题选择
                ListTile(
                  title: Text(
                    AppLocale.theme,
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  trailing: DropdownButton<String>(
                    value: GameConfig.theme,
                    items: ['classic', 'dark', 'candy'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          GameConfig.theme = v;
                          currentTheme = GameTheme.get(v);
                        });
                        setState(() {});
                        _saveSettings();
                      }
                    },
                  ),
                ),
                // 游戏模式
                ListTile(
                  title: Text(
                    AppLocale.mode,
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  trailing: DropdownButton<String>(
                    value: GameConfig.gameMode,
                    items: [
                      DropdownMenuItem(
                        value: 'endless',
                        child: Text(AppLocale.endless),
                      ),
                      DropdownMenuItem(
                        value: 'reach2048',
                        child: Text(AppLocale.reach2048),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => GameConfig.gameMode = v);
                        _saveSettings();
                      }
                    },
                  ),
                ),
                // 网格大小（需要重启游戏生效）
                ListTile(
                  title: Text(
                    AppLocale.gridSize,
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  trailing: DropdownButton<int>(
                    value: GameConfig.gridSize,
                    items: [3, 4, 5, 6].map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('${size}x$size'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null && v != GameConfig.gridSize) {
                        setDialogState(() {
                          GameConfig.gridSize = v;
                          _updateBoardSize(); // 重新计算尺寸
                        });
                        setState(() {
                          _updateBoardSize(); // 外层也更新
                        });
                        _clearGameProgress(); // 清除旧存档
                        _saveSettings();
                        // 提示
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocale.isChinese
                                  ? '网格尺寸已更改，请开始新游戏'
                                  : 'Grid size changed, start new game',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                // 提示延迟
                ListTile(
                  title: Text(
                    '${AppLocale.hintDelay}: ${GameConfig.hintDelaySeconds}s',
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  subtitle: Slider(
                    value: GameConfig.hintDelaySeconds.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 11,
                    label: '${GameConfig.hintDelaySeconds}s',
                    onChanged: (v) {
                      setDialogState(
                        () => GameConfig.hintDelaySeconds = v.toInt(),
                      );
                      _saveSettings();
                    },
                  ),
                ),
                // 最大撤销次数
                ListTile(
                  title: Text(
                    '${AppLocale.maxUndos}: ${GameConfig.maxUndoSteps}',
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                  subtitle: Slider(
                    value: GameConfig.maxUndoSteps.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '${GameConfig.maxUndoSteps}',
                    onChanged: (v) {
                      setDialogState(() {
                        GameConfig.maxUndoSteps = v.toInt();
                        undosLeft = GameConfig.maxUndoSteps;
                      });
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: Text(
                "OK",
                style: TextStyle(color: currentTheme.buttonColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建滑块行
  Widget _sliderRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: currentTheme.textColor),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: currentTheme.buttonColor,
        ),
      ],
    );
  }

  // 构建头部区域
  Widget _buildHeader() {
    return SizedBox(
      width: boardSize,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home_rounded,
                      color: currentTheme.textColor,
                      size: 28,
                    ),
                    onPressed: () {
                      _saveGameProgress();
                      setState(() => isGameStart = true);
                    },
                  ),
                  Text(
                    "2048",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: currentTheme.textColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      AudioManager.isBgmEnabled
                          ? Icons.music_note
                          : Icons.music_off,
                      color: currentTheme.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        AudioManager.toggleBGM();
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  _scoreBox(AppLocale.score, score),
                  const SizedBox(width: 8),
                  _scoreBox(AppLocale.best, highScore),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 操作按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 撤销按钮
                  _actionButton(
                    Icons.undo,
                    "${AppLocale.undo} ($undosLeft)",
                    history.isNotEmpty && undosLeft > 0,
                    performUndo,
                  ),
                  const SizedBox(width: 8),
                  // 重启按钮
                  _actionButton(
                    Icons.refresh,
                    AppLocale.restart,
                    true,
                    _showRestartConfirmation,
                  ),
                ],
              ),
              // 连击显示
              if (currentCombo > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: currentTheme.buttonColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "${AppLocale.combo} x$currentCombo",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建操作按钮
  Widget _actionButton(
    IconData icon,
    String label,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled
            ? currentTheme.buttonColor
            : Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // 构建分数盒子
  Widget _scoreBox(String label, int val) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: currentTheme.boardColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: currentTheme.emptyTileColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$val",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 构建游戏区域
  Widget _buildPlayArea() {
    Offset? dragStart;
    Offset dragDelta = Offset.zero;
    return GestureDetector(
      onPanStart: (details) {
        dragStart = details.localPosition;
        dragDelta = Offset.zero;
      },
      onPanUpdate: (details) {
        if (dragStart != null) dragDelta = details.localPosition - dragStart!;
      },
      onPanEnd: (details) {
        if (dragDelta.distance < 24) return;
        if (dragDelta.dx.abs() > dragDelta.dy.abs())
          move(dragDelta.dx > 0 ? Direction.right : Direction.left);
        else
          move(dragDelta.dy > 0 ? Direction.down : Direction.up);
      },
      child: Container(
        width: boardSize,
        height: boardSize,
        padding: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          color: currentTheme.boardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ...List.generate(
              GameConfig.gridSize * GameConfig.gridSize,
              (i) => _buildPositionedBox(
                i ~/ GameConfig.gridSize,
                i % GameConfig.gridSize,
                currentTheme.emptyTileColor,
              ),
            ),
            ...tiles.map(
              (tile) => AnimatedPositioned(
                key: ValueKey(tile.id),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                top: tile.x * (tileSize + margin),
                left: tile.y * (tileSize + margin),
                child: _buildTile(tile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建定位盒子（空格背景）
  Widget _buildPositionedBox(int r, int c, Color color) {
    return Positioned(
      top: r * (tileSize + margin),
      left: c * (tileSize + margin),
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // 构建方块
  Widget _buildTile(TileModel tile) {
    return TweenAnimationBuilder<double>(
      key: ValueKey("anim_${tile.id}_${tile.value}"),
      tween: Tween<double>(begin: 1.15, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: tile.merged ? scale : 1.0,
          child: Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: _getTileColor(tile.value),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                "${tile.value}",
                style: TextStyle(
                  fontSize: tile.value < 100
                      ? 28
                      : (tile.value < 10000 ? 22 : 18),
                  fontWeight: FontWeight.bold,
                  color: tile.value < 8
                      ? const Color(0xFF776E65)
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 获取方块颜色
  Color _getTileColor(int val) {
    return currentTheme.getTileColor(val);
  }

  // 构建游戏结束遮罩
  Widget _buildGameOverOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: currentTheme.backgroundColor.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocale.gameOver,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: currentTheme.textColor,
              ),
            ),
            Text(
              "${AppLocale.finalScore}: $score",
              style: TextStyle(fontSize: 28, color: currentTheme.buttonColor),
            ),
            const SizedBox(height: 40),
            _menuButton(AppLocale.again, initGame),
            const SizedBox(height: 15),
            _menuButton(AppLocale.back, () {
              _clearGameProgress(); // 清除存档以防止继续游戏加载game over状态
              setState(() {
                isGameOver = false;
                isGameStart = true;
              });
            }),
          ],
        ),
      ),
    );
  }

  // 构建菜单按钮
  Widget _menuButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: currentTheme.buttonColor,
        foregroundColor: Colors.white,
        fixedSize: const Size(200, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// 方向枚举
enum Direction { up, down, left, right }
