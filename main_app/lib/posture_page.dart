import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class PosturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SquatVideoUploader(),
    );
  }
}

class SquatVideoUploader extends StatefulWidget {
  @override
  _SquatVideoUploaderState createState() => _SquatVideoUploaderState();
}

class _SquatVideoUploaderState extends State<SquatVideoUploader> {
  File? selectedVideo;
  bool isLoading = false;
  String? analyzedVideoPath;
  VideoPlayerController? _controller;
  double videoProgress = 0.0;

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        selectedVideo = File(result.files.single.path!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video selected successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video selected')),
      );
    }
  }

  Future<void> uploadAndAnalyzeVideo() async {
    if (selectedVideo == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.220.134:5001/analyze'), // Update with your backend IP
      );
      request.files.add(await http.MultipartFile.fromPath('video', selectedVideo!.path));

      final response = await request.send();
      

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/analyzed_video.mp4';

        final fileStream = response.stream.asBroadcastStream();
        final file = File(filePath);
        final sink = file.openWrite();

        await fileStream.pipe(sink);
        await sink.close();

        setState(() {
          analyzedVideoPath = filePath;
          _controller = VideoPlayerController.file(File(analyzedVideoPath!))
            ..addListener(() {
              setState(() {
                videoProgress = _controller!.value.position.inMilliseconds.toDouble() /
                    _controller!.value.duration.inMilliseconds.toDouble();
              });
            })
            ..initialize().then((_) {
              setState(() {});
              _controller!.play();
            });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video analyzed successfully!')),
        );
      } else {
        throw Exception('Failed to analyze video. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: pickVideo,
                child: Text('Select Squat Video'),
              ),
              if (selectedVideo != null) ...[
                SizedBox(height: 20),
                Text('Video Selected'),
              ],
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (_controller != null && _controller!.value.isInitialized)
                Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    SizedBox(height: 10),
                    Slider(
                      value: videoProgress,
                      onChanged: (value) {
                        final position = _controller!.value.duration * value;
                        _controller!.seekTo(position);
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                      min: 0.0,
                      max: 1.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _controller!.value.position.toString().split('.').first,
                        ),
                        Text(
                          _controller!.value.duration.toString().split('.').first,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                      child: Icon(
                        _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              if (!isLoading)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: uploadAndAnalyzeVideo,
                  child: Text('Upload and Analyze'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
