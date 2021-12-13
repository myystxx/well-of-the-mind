import 'dart:io';
import 'dart:core';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/domain/rss_category.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:wotm_app/constants.dart';
import 'package:wotm_app/screens/main-screen.dart';
import 'article-read-screen.dart';

const _titleText = 'Article';
const _imageText = 'articles';

class ArticlesScreen extends StatefulWidget {
  final String title = "Hello!";

  @override
  _ArticlesScreenState createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  static String collectionDbName = 'saved_articles';

  CollectionReference articles =
      FirebaseFirestore.instance.collection(collectionDbName);

  static const List feed_titles = [
    'Psychology Today',
    'Psychology Matters',
    'What is Psychology',
    'PsycPORT: Psychology Newswire',
  ];
  static const List feed_sources = [
    'https://www.psychologytoday.com/sg/front/feed',
    'https://www.psychologymatters.asia/rss/',
    'http://www.whatispsychology.biz/feed',
    'https://www.apa.org/news/psycport/psycport-rss.xml',
  ];

  static const String FEED_URL =
      'http://www.whatispsychology.biz/feed'; //default feed url
  RssFeed _feed;
  String _title;
  String _buildDate;
  static const String loadingFeedMsg = 'Loading Feed...';
  static const String feedLoadErrorMsg = 'Error Loading Feed.';
  static const String feedOpenErrorMsg = 'Error Opening Feed.';
  static const String placeholderImg = 'images/no-image.png';
  dynamic _userSavedList;
  bool _isArticleList = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    updateTitle(widget.title);
    load(FEED_URL);
  }

  updateTitle(title) {
    setState(() {
      _title = title;
    });
  }

  updateFeedDate(buildDate) {
    if (buildDate == null) {
      setState(() {
        _buildDate = '';
      });
    } else {
      var trimDate = buildDate.split(' ');
      String finalDate =
          '${trimDate[0]} ${trimDate[1]} ${trimDate[2]} ${trimDate[3]}';
      setState(() {
        _buildDate = '$finalDate';
      });
    }
  }

  updateFeed(feed) {
    setState(() {
      _feed = feed;
    });
  }

  changeToSavedArticle(isArticleList) {
    setState(() {
      _isArticleList = isArticleList;
    });
  }

  void openFeed(BuildContext context, String url, String title) {
    Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => ArticleView(url, title)));
  }

  load(url) async {
    updateTitle(loadingFeedMsg);
    updateFeedDate(null);
    loadFeed(url).then((result) {
      if (null == result || result.toString().isEmpty) {
        updateTitle(feedLoadErrorMsg);
        return;
      }
      updateFeed(result);
      updateTitle('You are reading from "${_feed.title}"');
      updateFeedDate(result.lastBuildDate);
    });
  }

  Future<RssFeed> loadFeed(url) async {
    try {
      int startTime = new DateTime.now().millisecond;
      final client = http.Client();
      final response = await client.get(Uri.parse(url));
      int endTime = new DateTime.now().millisecond - startTime;
      print("feed: $endTime");
      return RssFeed.parse(response.body);
    } catch (e) {
      print("fail to load feed");
    }
  }

  title(title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18.0, fontWeight: FontWeight.w700, fontFamily: kBodyFont),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  subtitle(subTitle) {
    return Text(
      subTitle,
      style:
          TextStyle(color: Colors.black, fontSize: 14.0, fontFamily: kBodyFont, fontWeight: FontWeight.w400),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  showDate(date) {
    return Text(
      date,
      style:
          TextStyle(color: Colors.black, fontSize: 12.0, fontFamily: kBodyFont),
      maxLines: 1,
    );
  }

  //if RSS feed contains an image, use this to generate
  thumbnail(imageUrl) {
    return Padding(
      padding: EdgeInsets.only(left: 15.0),
      child: CachedNetworkImage(
        placeholder: (context, url) => Image.asset(placeholderImg),
        imageUrl: imageUrl,
        height: 50,
        width: 70,
        alignment: Alignment.center,
        fit: BoxFit.fill,
      ),
    );
  }

  rightIcon() {
    return Icon(
      Icons.keyboard_arrow_right,
      color: Colors.grey,
      size: 30.0,
    );
  }

  tagBuilder(List tags) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: tags.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 10.0,
          margin: EdgeInsets.all(5.0),
          padding: EdgeInsets.all(5.0),
          color: Colors.blue[50],
          child: Text(tags[index].value),
        );
      },
    );
  }

  list() {
    return ListView.builder(
      itemCount: _feed.items.length,
      itemBuilder: (BuildContext context, int index) {
        var item = _feed.items[index];
        return Container(
          margin: EdgeInsets.all(7.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: ListTile(
                  minLeadingWidth: 20.0,
                  title: title(item.title),
                  subtitle: subtitle(item.description),
                  trailing: rightIcon(),
                  tileColor: Colors.white70,
                  contentPadding: EdgeInsets.all(10.0),
                  onTap: () => openFeed(context, item.link, item.title),
                ),
              ),
              item.categories.isEmpty
                  ? SizedBox(height: 1.0)
                  : Container(height: 40.0, child: tagBuilder(item.categories)),
            ],
          ),
        );
      },
    );
  }

  isFeedEmpty() {
    return _feed == null || _feed.items == null;
  }

  Widget body() {
    return isFeedEmpty()
        ? Center(
            child: CircularProgressIndicator(),
          )
        : list();
  }

  Widget feedChoices(List sources, List titles) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: sources.length,
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          onTap: () {
            load(sources[index]);
          },
          child: Card(
            color: Colors.pink[100],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                titles[index],
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kBackgroundDecoration(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20.0,
                  backgroundImage: AssetImage('images/icons/articles.png'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'Articles',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: kTitleFont,
                    ),
                  ),
                ),
                SizedBox(width: 80.0),
                ActionButton(
                  onPressed: () =>
                      _isArticleList ? _viewSavedArticle() : _viewRSSfeed(),
                  icon: _isArticleList
                      ? Icon(Icons.folder_special_rounded)
                      : Icon(Icons.article_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 10.0),
              child: _isArticleList
                  ? ListView(
                      children: <Widget>[
                        Title(
                          color: Colors.black,
                          child: Text(
                            "Mind Digest",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kTitleFont,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        Container(
                          height: 50.0,
                          child: feedChoices(feed_sources, feed_titles),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          '$_title\n $_buildDate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: kBodyFont),
                        ),
                        SizedBox(height: 10.0),
                        Container(
                          height: 500.0,
                          child: body(),
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Title(
                          color: Colors.black,
                          child: Text(
                            "Saved Articles",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kTitleFont,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        Expanded(child: savedArticles()),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  _viewRSSfeed() {
    changeToSavedArticle(true);
    load(FEED_URL);
  }

  _viewSavedArticle() {
    //RETRIEVE FILTERED USER DATA
    if (HomeScreen.userKey != null) {
      try {
        int startTime = new DateTime.now().millisecond;
        articles
            .where('user', isEqualTo: HomeScreen.userKey)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isEmpty) {
            displayDialog(context, 'No saved articles found!');
          } else {
            changeToSavedArticle(false);
            _userSavedList = querySnapshot.docs;
            int endTime = new DateTime.now().millisecond - startTime;
            print("save article: $endTime");
          }
        });
      } catch (e) {
        displayDialog(context, 'Something went wrong $e');
      }
    } else {
      displayDialog(context, 'Something went wrong');
    }
  }

  savedArticles() {
    return ListView.builder(
        itemCount: _userSavedList.length,
        itemBuilder: (BuildContext context, int index) {
          var doc = _userSavedList[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: Container(
              margin: EdgeInsets.all(10.0),
              child: ListTile(
                title: title(doc['title']),
                subtitle: subtitle(doc['description']),
                trailing: rightIcon(),
                tileColor: Colors.white70,
                contentPadding: EdgeInsets.all(10.0),
                onTap: () => openFeed(context, doc['url'], doc['title']),
              ),
            ),
          );
        });
  }
}
