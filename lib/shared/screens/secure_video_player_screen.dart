import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/constants/app_colors.dart';

class SecureVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const SecureVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<SecureVideoPlayerScreen> createState() => _SecureVideoPlayerScreenState();
}

class _SecureVideoPlayerScreenState extends State<SecureVideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        topActions: [
           const SizedBox(width: 8.0),
           Expanded(
             child: Text(
               _controller.metadata.title,
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 18.0,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          // Video ended
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _controller.value.isFullScreen 
              ? null 
              : AppBar(
                  backgroundColor: Colors.transparent,
                  leading: const BackButton(color: Colors.white),
                  title: Text(widget.title, style: const TextStyle(color: Colors.white)),
                ),
          body: Center(child: player),
        );
      },
    );
  }
}
