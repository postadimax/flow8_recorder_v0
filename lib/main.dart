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
  final AudioRecorder audioRecorder = AudioRecorder();
  bool isRecording = false;
  List<bool> armedChannels = List.generate(10, (index) => true);
  
  // Nomi canali come da tuo screenshot
  final List<String> channelNames = [
    "MIC/LINE 1", "MIC/LINE 2", "MIC/LINE 3", "MIC/LINE 4",
    "INST 5", "INST 6", "INST 7", "INST 8", "MAIN L", "MAIN R"
  ];

  // Simulazione VU-Meter (Valori da 0.0 a 1.0)
  List<double> volumeLevels = List.generate(10, (index) => 0.0);
  Timer? timer;

  void startRecording() async {
    if (await audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/flow_session_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 10, sampleRate: 48000), 
        path: path
      );

      setState(() => isRecording = true);
      
      // Simula il movimento dei VU-Meter mentre registri
      timer = Timer.periodic(Duration(milliseconds: 100), (t) {
        setState(() {
          volumeLevels = List.generate(10, (index) => armedChannels[index] ? (index == 0 ? 0.7 : 0.1) : 0.0);
        });
      });
    }
  }

  void stopRecording() async {
    await audioRecorder.stop();
    timer?.cancel();
    setState(() {
      isRecording = false;
      volumeLevels = List.generate(10, (index) => 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.cyan,
            child: Text("F8", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        title: Text("FLOW 8 STUDIO", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900)),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, size: 14, color: Colors.cyan),
                SizedBox(width: 4),
                Text("USB LINK ACTIVE", style: TextStyle(fontSize: 10, color: Colors.cyan, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Sezione Progetto
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF0A0A0A),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("PROGETTO", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                hintText: "FLOW_SESSION",
                hintStyle: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
          ),
          
          // Lista Canali
          Expanded(
            child: ListView.builder(
              itemCount: 6, // Mostriamo i primi 6 come nello screenshot
              itemBuilder: (context, index) => buildChannelRow(index),
            ),
          ),

          // Bottom Bar
          Container(
            height: 100,
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TIME", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text("00:00:00", style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("DATA", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text("0.0M", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Tasto REC Grande
                GestureDetector(
                  onTap: isRecording ? stopRecording : startRecording,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey, width: 2)),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? Colors.red : Color(0xFF222222),
                          boxShadow: [if(isRecording) BoxShadow(color: Colors.red, blurRadius: 15)],
                        ),
                        child: Center(child: Icon(isRecording ? Icons.stop : Icons.circle, color: isRecording ? Colors.white : Colors.red, size: 30)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChannelRow(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text("CH", style: TextStyle(color: Colors.grey, fontSize: 8)),
              Text("${index + 1}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channelNames[index], style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                // VU-METER
                Stack(
                  children: [
                    Container(height: 16, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 100),
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.5 * volumeLevels[index],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          // Pulsante ARM/REC
          GestureDetector(
            onTap: () => setState(() => armedChannels[index] = !armedChannels[index]),
            child: Container(
              width: 50,
              height: 35,
              decoration: BoxDecoration(
                color: armedChannels[index] ? (isRecording ? Colors.red : Color(0xFF2A2A2A)) : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: armedChannels[index] ? Colors.redAccent : Colors.white10),
              ),
              child: Center(
                child: Text(
                  isRecording && armedChannels[index] ? "REC" : "ARM",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}