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
  bool _isHighDefinition = false; // Track locally

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController({int startAt = 0}) {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: _isHighDefinition,
        enableCaption: false,
        startAt: startAt,
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

  void _toggleQuality(bool isHd) {
    if (_isHighDefinition == isHd) return;

    final currentPos = _controller.value.position.inSeconds;
    final isPlaying = _controller.value.isPlaying;

    _controller.removeListener(_listener);
    _controller.dispose();

    setState(() {
      _isHighDefinition = isHd;
      _isPlayerReady = false;
      _initializeController(startAt: currentPos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        // Key is important to force rebuild when controller changes
        key: ValueKey(_controller.hashCode), 
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
        bottomActions: [
          const SizedBox(width: 14.0),
          CurrentPosition(),
          const SizedBox(width: 8.0),
          ProgressBar(isExpanded: true, colors: const ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          )),
          RemainingDuration(),
          const PlaybackSpeedButton(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              _showSettingsModal(context);
            },
          ),
          const FullScreenButton(),
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

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.hd, color: Colors.white),
                title: const Text('Quality', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () {
                   Navigator.pop(context);
                   _showQualitySelector(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
                trailing: Text(
                  '${_controller.value.playbackRate}x',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                   Navigator.pop(context);
                   _showSpeedSelector(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Track selected label for UI feedback (Best effort)
  String _selectedQualityLabel = 'Auto';

  void _showQualitySelector(BuildContext context) {
     final qualities = ['Auto', '144p', '240p', '360p', '480p', '720p', '1080p'];
     
     showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Quality', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: qualities.length,
                  itemBuilder: (context, index) {
                    final quality = qualities[index];
                    final isSelected = _selectedQualityLabel == quality;
                    
                    return ListTile(
                      title: Text(quality, style: const TextStyle(color: Colors.white)),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        Navigator.pop(context);
                        
                        setState(() {
                          _selectedQualityLabel = quality;
                        });

                        // Map logic: 720p and 1080p -> Force HD, others -> Auto/Std
                        // This is a "Best Effort" mapping as YouTube API only reliably supports "Force HD" boolean in this wrapper.
                        if (quality == '720p' || quality == '1080p') {
                          _toggleQuality(true);
                        } else {
                          _toggleQuality(false);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedSelector(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: speeds.map((speed) {
            return ListTile(
              title: Text('${speed}x', style: const TextStyle(color: Colors.white)),
              trailing: _controller.value.playbackRate == speed 
                  ? const Icon(Icons.check, color: AppColors.primary) 
                  : null,
              onTap: () {
                _controller.setPlaybackRate(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }}
