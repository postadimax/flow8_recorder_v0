import 'package:flutter/material.dart';
import 'package:record/record.dart'; 
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() => runApp(MaterialApp(
      home: Flow8Studio(),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    ));

class Flow8Studio extends StatefulWidget {
  @override
  _Flow8StudioState createState() => _Flow8StudioState();
}

class _Flow8StudioState extends State<Flow8Studio> {
  final AudioRecorder audioRecorder = AudioRecorder(); // Torna a AudioRecorder
  bool isRecording = false;
  List<bool> armedChannels = List.generate(10, (index) => true);
  
  final List<String> channelNames = [
    "MIC/LINE 1", "MIC/LINE 2", "MIC/LINE 3", "MIC/LINE 4",
    "INST 5", "INST 6", "INST 7", "INST 8", "MAIN L", "MAIN R"
  ];

  List<double> volumeLevels = List.generate(10, (index) => 0.0);
  Timer? timer;
  Stopwatch stopwatch = Stopwatch();
  String timerDisplay = "00:00:00";

  void startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/flow_session_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        // Configurazione moderna per Record 5.2.0
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 48000,
          numChannels: 10,
        );

        await audioRecorder.start(config, path: path);

        stopwatch.start();
        setState(() => isRecording = true);
        
        timer = Timer.periodic(Duration(milliseconds: 100), (t) {
          setState(() {
            timerDisplay = _formatDuration(stopwatch.elapsed);
            volumeLevels = List.generate(10, (index) => 
              armedChannels[index] ? (0.2 + (t.tick % 5) / 10) : 0.0);
          });
        });
      }
    } catch (e) {
      print("Errore: $e");
    }
  }

  void stopRecording() async {
    await audioRecorder.stop();
    stopwatch.stop();
    stopwatch.reset();
    timer?.cancel();
    setState(() {
      isRecording = false;
      timerDisplay = "00:00:00";
      volumeLevels = List.generate(10, (index) => 0.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("FLOW 8 STUDIO PRO"),
        actions: [Icon(Icons.bolt, color: Colors.cyanAccent), SizedBox(width: 20)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) => _buildChannelRow(index),
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildChannelRow(int index) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Text("${index + 1}", style: TextStyle(color: Colors.grey)),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channelNames[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                LinearProgressIndicator(value: volumeLevels[index], backgroundColor: Colors.black, color: Colors.greenAccent),
              ],
            ),
          ),
          Switch(
            value: armedChannels[index],
            onChanged: (v) => setState(() => armedChannels[index] = v),
            activeColor: Colors.red,
          )
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Color(0xFF0A0A0A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timerDisplay, style: TextStyle(fontSize: 24, color: Colors.cyanAccent)),
          FloatingActionButton(
            backgroundColor: isRecording ? Colors.red : Colors.grey[800],
            onPressed: isRecording ? stopRecording : startRecording,
            child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
          ),
          Text("DISK: OK", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
