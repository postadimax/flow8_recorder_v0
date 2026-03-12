import 'package:flutter/material.dart';
import 'package:record/record.dart'; // Versione stabile 4.4.4
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

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
  // Inizializzazione per record 4.4.4
  final Record audioRecorder = Record();
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
        
        // Configurazione specifica per Record 4.4.4
        await audioRecorder.start(
          path: path,
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          samplingRate: 48000,
          numChannels: 10, // Importante per i 10 canali USB del FLOW 8
        );

        stopwatch.start();
        setState(() => isRecording = true);
        
        // Animazione VU-Meter e Timer
        timer = Timer.periodic(Duration(milliseconds: 100), (t) {
          setState(() {
            timerDisplay = _formatDuration(stopwatch.elapsed);
            // Simulazione livelli audio (per test grafica)
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
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: Text("F8", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        title: Text("FLOW 8 STUDIO", style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.white)),
        actions: [
          _buildUsbBadge(),
        ],
      ),
      body: Column(
        children: [
          _buildProjectHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: 8, // Mostriamo gli 8 canali principali
              itemBuilder: (context, index) => _buildChannelRow(index),
            ),
          ),
          _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildUsbBadge() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 14, color: Colors.cyanAccent),
          SizedBox(width: 4),
          Text("USB LINK ACTIVE", style: TextStyle(fontSize: 9, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Text("PROGETTO: ", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Text("FLOW_SESSION_01", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelRow(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Text("CH", style: TextStyle(color: Colors.grey, fontSize: 8)),
                Text("${index + 1}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channelNames[index], style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Stack(
                  children: [
                    Container(height: 12, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 100),
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.5 * volumeLevels[index],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent, Colors.yellow]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          GestureDetector(
            onTap: () => setState(() => armedChannels[index] = !armedChannels[index]),
            child: Container(
              width: 55,
              height: 35,
              decoration: BoxDecoration(
                color: armedChannels[index] ? (isRecording ? Colors.red : Color(0xFF330000)) : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: armedChannels[index] ? Colors.red : Colors.white10),
              ),
              child: Center(
                child: Text(
                  armedChannels[index] ? "ARMED" : "OFF",
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("REC TIME", style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text(timerDisplay, style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          GestureDetector(
            onTap: isRecording ? stopRecording : startRecording,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isRecording ? Colors.red : Colors.white24, width: 2),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? Colors.red : Color(0xFF222222),
                    boxShadow: [
                      if (isRecording) BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                    ],
                  ),
                  child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("DISK SPACE", style: TextStyle(color: Colors.grey, fontSize: 9)),
              Text("42.5 GB", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
