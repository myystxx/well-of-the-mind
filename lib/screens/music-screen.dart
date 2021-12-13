import 'dart:async';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import 'package:wotm_app/spotify.dart';

const _titleText = 'Relax';
const _imageText = 'music';

enum PlayerState { stopped, playing, paused }
const exerciseText = ['', 'Breathe in', 'Breathe out', 'Good work!'];

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key key}) : super(key: key);

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

//TODO: include a writeup on the usefulness of meditation
class _MusicScreenState extends State<MusicScreen> {
  String _audio_url;
  String _external_url;
  String _title;
  String _artist;
  dynamic _tracks;
  AudioPlayer player;
  Timer timer;
  int _index; // keep track of tracks played
  Duration duration;
  Duration position;
  PlayerState playerState = PlayerState.stopped;
  int _count; // tracker for exerciseText
  bool _userStop = false;

  get isPlaying => playerState == PlayerState.playing;
  get isStopped => playerState == PlayerState.stopped;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    _count = 0;
    _index = 0;
    getPlaylist();
    initAudioPlayer();
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    player.stop();
    timer.cancel();
    super.dispose();
  }

  updateDetails(title, artist) {
    setState(() {
      _title = title;
      _artist = artist;
    });
  }

  updateTracks(tracks) {
    setState(() {
      _tracks = tracks;
    });
  }

  updateUser(stop) {
    setState(() {
      _userStop = stop;
    });
  }

  updateCount(count) {
    setState(() {
      _count = count;
    });
  }

  nextTrack() {
    setState(() {
      _index = _index + 1;
    });
  }

  getPlaylist() async {
    SpotifyAuth spotify = SpotifyAuth();
    var data = await spotify.fetchShow();
    List<dynamic> playlist = [];
    for (int i = 0; i < data.length - 2; i++) {
      _title = data['items'][i]['track']['name'];
      _artist = data['items'][i]['track']['artists'][0]['name'];
      _audio_url = data['items'][i]['track']['preview_url'];
      _external_url = data['items'][i]['track']['external_urls']['spotify'];
      Track track = Track(_title, _artist, _audio_url, _external_url);
      updateDetails(_title, _artist);
      playlist.add(track);
    }
    updateTracks(playlist);
  }

  void initAudioPlayer() {
    player = AudioPlayer();
    _positionSubscription = player.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = player.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        if (_userStop) {
          stop();
          setState(() {
            position = duration;
          });
        } else {
          onComplete();
          setState(() {
            position = duration;
          });
        }
      }
    }, onError: (msg) {
      print(msg);
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future play(url) async {
    setState(() {
      playerState = PlayerState.playing;
    });
    updateCount(1);
    await player.play(url);
    exerciseUtils();
  }

  Future pause() async {
    await player.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    updateCount(3); // set text to end exercise
    await player.stop();
    setState(() {
      _index = 0; // reset track list
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  void onComplete() {
    // loop next music in list
    nextTrack();
    loopMusic();
  }

  exerciseUtils() {
    int currentTime = position.inSeconds.toInt();
    int endTime = duration.inSeconds.toInt();
    timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (isPlaying && currentTime < endTime) {
        switch (_count) {
          case 0:
            {
              updateCount(1);
              print(_count);
            }
            break;
          case 1:
            {
              updateCount(2);
              print(_count);
            }
            break;
          case 2:
            {
              updateCount(1);
              print(_count);
            }
            break;
          default:
            break;
        }
      } else if (isPaused && currentTime < endTime) {
        updateCount(_count);
        exerciseUtils();
      }
    });
  }

  launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: false,
      );
      return;
    }
  }

  Future loopMusic() async {
    Track track;
    int length = _tracks.length;
    if (_index < length - 1 && !isStopped) {
      track = _tracks[_index];
      updateDetails(track.title, track.artist);
      updateCount(1);
      play(track.audio_url);
    } else {
      stop();
    }
  }

  Widget _buildDetails() => !isStopped
      ? Column(
          children: <Widget>[
            Text("Now you are listening to $_title"),
            Text("By $_artist"),
            FlatButton(
                hoverColor: Colors.blueGrey,
                onPressed: () {
                  updateUser(true);
                  stop();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    color: Colors.white70,
                    padding:
                        EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),
                    child: Text("Stop"),
                  ),
                )),
            FlatButton(
              onPressed: () => launchUrl(_external_url),
              child: Text(
                'Listen to the full song here',
                style:
                    TextStyle(color: Colors.brown, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        )
      : Text('');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kBackgroundDecoration(3),
      child: Column(
        children: <Widget>[
          kTitleContainer(_titleText, _imageText),
          Container(
            padding:
                EdgeInsets.only(top: 50, bottom: 50, left: 100, right: 100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.white70,
                padding: EdgeInsets.all(10.0),
                height: 60.0,
                child: Text(
                    'Focus on your breath,\nand be in the present moment,\n'),
              ),
            ),
          ),
          //top widget
          Center(
            child: Text(
              exerciseText[_count],
              style: TextStyle(
                fontSize: 20.0,
                fontFamily: kTitleFont,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: 10,
            ),
            child: IconButton(
              icon: isPlaying
                  ? Icon(Icons.pause_circle_filled)
                  : Icon(Icons.play_circle_fill),
              iconSize: 100.0,
              color: Colors.pink[200],
              hoverColor: Colors.black,
              onPressed: () => isPlaying ? pause() : play(_audio_url),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            child: _buildDetails(),
          ),
        ],
      ),
    );
  }
}
