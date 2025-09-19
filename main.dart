import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const HerbQuizApp());
}

class HerbQuizApp extends StatelessWidget {
  const HerbQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中藥辨識測驗',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(250, 60),
      textStyle: const TextStyle(fontSize: 18),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("🌿 中藥辨識測驗")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("請選擇功能",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DifficultyPage()));
              },
              child: const Text("開始測驗"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReviewPage()));
              },
              child: const Text("錯題複習"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ScoreHistoryPage()));
              },
              child: const Text("歷史成績"),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultyPage extends StatelessWidget {
  const DifficultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(250, 60),
      textStyle: const TextStyle(fontSize: 18),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("選擇難度")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            QuizPage(mode: "初級", questionCount: 10)));
              },
              child: const Text("初級（10題）"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            QuizPage(mode: "中級", questionCount: 20)));
              },
              child: const Text("中級（20題）"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            QuizPage(mode: "高級", questionCount: 30)));
              },
              child: const Text("高級（30題）"),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String mode;
  final int questionCount;

  const QuizPage({super.key, required this.mode, required this.questionCount});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final List<String> herbs = [
    "北五味", "紫蘇葉", "枳殼", "川烏", "車前子",
    "白花蛇吞草", "黃耆", "白前", "豨薟草"
    // ⚠️ 測試版只放9種，之後可補全120種
  ];

  late List<String> quizList;
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String feedback = "";
  Timer? timer;
  int timeLeft = 10;

  static List<String> wrongList = [];
  static List<Map<String, dynamic>> scoreHistory = [];

  late List<String> currentOptions; // ✅ 固定當前題目選項

  @override
  void initState() {
    super.initState();
    quizList = List<String>.from(herbs)..shuffle();
    quizList = quizList.take(widget.questionCount).toList();
    generateOptions(); // 生成第一題選項
    startTimer();
  }

  void startTimer() {
    timeLeft = 10;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        checkAnswer("時間到");
      }
    });
  }

  void generateOptions() {
    String correct = quizList[currentIndex];
    List<String> options = [correct];

    // 抽 3 個錯誤選項
    List<String> wrongs = List<String>.from(herbs)..remove(correct);
    wrongs.shuffle();
    options.addAll(wrongs.take(3));

    options.shuffle();
    currentOptions = options; // ✅ 存起來
  }

  void checkAnswer(String selected) {
    if (answered) return;
    setState(() {
      answered = true;
      timer?.cancel();
      if (selected == quizList[currentIndex]) {
        score++;
        feedback = "✔️ 答對了！";
        wrongList.remove(quizList[currentIndex]);
      } else {
        if (selected != "時間到") {
          feedback = "❌ 答錯了！ 正確答案：${quizList[currentIndex]}";
        } else {
          feedback = "⌛ 時間到！ 正確答案：${quizList[currentIndex]}";
        }
        if (!wrongList.contains(quizList[currentIndex])) {
          wrongList.add(quizList[currentIndex]);
        }
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        if (currentIndex < quizList.length - 1) {
          currentIndex++;
          answered = false;
          feedback = "";
          generateOptions(); // ✅ 換題目才生成新選項
          startTimer();
        } else {
          timer?.cancel();
          _saveScore();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultPage(score: score, total: quizList.length),
            ),
          );
        }
      });
    });
  }

  void _saveScore() {
    scoreHistory.insert(0, {
      "date": DateTime.now(),
      "mode": widget.mode,
      "score": score,
      "total": quizList.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    String herb = quizList[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.mode}模式 - 第 ${currentIndex + 1}/${quizList.length} 題"),
        actions: [
          TextButton(
            onPressed: () {
              timer?.cancel();
              _saveScore();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ResultPage(score: score, total: quizList.length)),
              );
            },
            child: const Text("結束測驗",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("剩餘時間：$timeLeft 秒",
                style: const TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 10),
            Image.network(
              "https://a0909270933-blip.github.io/herbs-images/$herb.jpg",
              height: 200,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 200, color: Colors.grey,
                      child: const Center(child: Text("無圖片"))),
            ),
            const SizedBox(height: 20),
            Text("請問這是什麼藥材？",
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ...currentOptions.map((opt) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: answered
                        ? (opt == quizList[currentIndex]
                            ? Colors.green
                            : (opt == "時間到"
                                ? Colors.grey
                                : Colors.red))
                        : null,
                  ),
                  onPressed: () => checkAnswer(opt),
                  child: Text(opt),
                )),
            const SizedBox(height: 20),
            Text(feedback, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int total;

  const ResultPage({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("測驗結果")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🌟 本回合結束！", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Text("總分：$score / $total",
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomePage()));
              },
              child: const Text("回首頁"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QuizPage(
                            mode: "再挑戰", questionCount: total)));
              },
              child: const Text("再挑戰一次"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ReviewPage()));
              },
              child: const Text("查看錯題"),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  @override
  Widget build(BuildContext context) {
    final wrongList = _QuizPageState.wrongList.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("錯題複習"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _QuizPageState.wrongList.clear();
              });
            },
            child:
                const Text("清空錯題", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: wrongList.isEmpty
          ? const Center(child: Text("目前沒有錯題 🎉"))
          : ListView.builder(
              itemCount: wrongList.length,
              itemBuilder: (context, index) {
                String herb = wrongList[index];
                return ListTile(
                  leading: Image.network(
                    "https://a0909270933-blip.github.io/herbs-images/$herb.jpg",
                    width: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: 50, color: Colors.grey,
                            child: const Center(child: Text("無圖"))),
                  ),
                  title: Text(herb),
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => QuizPage(
                                mode: "錯題測驗",
                                questionCount: wrongList.length)));
                  },
                );
              },
            ),
    );
  }
}

class ScoreHistoryPage extends StatelessWidget {
  const ScoreHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = _QuizPageState.scoreHistory;

    return Scaffold(
      appBar: AppBar(title: const Text("歷史成績")),
      body: history.isEmpty
          ? const Center(child: Text("目前沒有紀錄"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return ListTile(
                  title: Text(
                      "${record['mode']} - ${record['score']}/${record['total']}"),
                  subtitle: Text(record['date'].toString()),
                );
              },
            ),
    );
  }
}
