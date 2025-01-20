import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizPage(),
      routes: {
        '/result': (context) => ResultPage(),
      },
    );
  }
}

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> quizData = [];
  List<String> selectedAnswers = [];
  List<bool> isCorrectAnswer = [];
  int currentQuestionIndex = 0;
  int score = 0;
  int remainingAttempts = 10; // Total attempts
  bool isLoading = true;
  bool testCompleted = false;

  @override
  void initState() {
    super.initState();
    fetchQuizData();
  }

  Future<void> fetchQuizData() async {
    const String apiUrl =
        'https://api.jsonserve.com/Uw5CrX'; // Your API endpoint
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(response.body);
        print('API Response: ${response.body}'); // Debugging

        if (parsedResponse is Map<String, dynamic> &&
            parsedResponse.containsKey('questions')) {
          final questions = parsedResponse['questions'];

          if (questions is List) {
            setState(() {
              quizData = questions;
              isLoading = false;
            });
          } else {
            showError('Questions data is not a list.');
          }
        } else {
          showError('Unexpected API response format.');
        }
      } else {
        showError('Failed to load quiz data.');
      }
    } catch (e) {
      showError('Error fetching quiz data: $e');
      print('Error: $e');
    }
  }

  void showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void selectOption(int index, bool isCorrect) {
    setState(() {
      if (!testCompleted) {
        // If the question is already answered, update the option.
        if (selectedAnswers.length > currentQuestionIndex) {
          selectedAnswers[currentQuestionIndex] =
              quizData[currentQuestionIndex]['options'][index]['description'];
          isCorrectAnswer[currentQuestionIndex] = isCorrect;
        } else {
          selectedAnswers.add(
              quizData[currentQuestionIndex]['options'][index]['description']);
          isCorrectAnswer.add(isCorrect);
        }
        if (isCorrect) {
          score++;
        } else {
          score--;
        }
      }
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < quizData.length - 1) {
        currentQuestionIndex++;
      }
    });
  }

  void previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
      }
    });
  }

  void finishTest() {
    setState(() {
      testCompleted = true;
    });

    // Navigate to Result Page with the score
    Navigator.pushNamed(context, '/result', arguments: score);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quizData.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No quiz data available.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final currentQuestion = quizData[currentQuestionIndex];
    final questionText =
        currentQuestion['description'] ?? 'No question text available';
    final options = currentQuestion['options'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: Stack(
        children: [
          // Background Sci-Fi Animation (with dynamic gradient colors)
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.blueAccent.shade400,
                    Colors.cyanAccent.shade700,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: AnimatedOpacity(
                opacity: testCompleted ? 0.5 : 1.0,
                duration: Duration(seconds: 3),
                child: Container(), // Empty container to apply the opacity
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1}/${quizData.length}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  questionText,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                // Render the options
                ...options
                    .asMap()
                    .map((index, option) {
                      String displayOption =
                          option['description'] ?? 'Invalid option';
                      bool isCorrect = option['is_correct'] ?? false;
                      return MapEntry(
                        index,
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                selectedAnswers.contains(displayOption)
                                    ? (isCorrect ? Colors.green : Colors.red)
                                    : Colors.blue,
                              ),
                            ),
                            onPressed: () => selectOption(index, isCorrect),
                            child: Text(displayOption),
                          ),
                        ),
                      );
                    })
                    .values
                    .toList(),
                SizedBox(height: 20),
                Text(
                  'Remaining Attempts: $remainingAttempts',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                SizedBox(height: 20),
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentQuestionIndex > 0)
                      ElevatedButton(
                        onPressed: previousQuestion,
                        child: Text('Previous'),
                      ),
                    if (currentQuestionIndex < quizData.length - 1 &&
                        !testCompleted)
                      ElevatedButton(
                        onPressed: nextQuestion,
                        child: Text('Next'),
                      ),
                    if (!testCompleted)
                      ElevatedButton(
                        onPressed: finishTest,
                        child: Text('Finish Test'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final score = ModalRoute.of(context)!.settings.arguments as int;
    String feedback = '';
    Color color = Colors.green;

    if (score >= 8) {
      feedback = 'Amazing! You nailed it!';
      color = Colors.green;
    } else if (score >= 5) {
      feedback = 'Good Job! You did well!';
      color = Colors.blue;
    } else {
      feedback = 'Keep Trying! You can do better!';
      color = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Score:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '$score',
              style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 20),
            Text(
              feedback,
              style: TextStyle(
                  fontSize: 18, fontStyle: FontStyle.italic, color: color),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => QuizPage()));
              },
              child: Text('Restart Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
