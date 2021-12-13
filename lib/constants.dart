import 'package:flutter/material.dart';

// font family
const kTitleFont = 'GloriaHallelujah';
const kBodyFont = 'Nunito';

BoxDecoration kBackgroundDecoration(int backgroundIndex) => BoxDecoration(
      image: DecorationImage(
        image: AssetImage("images/background/$backgroundIndex.png"),
        fit: BoxFit.cover,
      ),
    );

Widget kTitleContainer(titleText, imageText) {
  return Container(
    color: Colors.white,
    padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
    child: Row(
      children: <Widget>[
        CircleAvatar(
          radius: 20.0,
          backgroundImage: AssetImage('images/icons/$imageText.png'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            titleText,
            style: TextStyle(
              fontSize: 20.0,
              fontFamily: kTitleFont,
            ),
          ),
        ),
      ],
    ),
  );
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    Key key,
    this.onPressed,
    this.icon,
  }) : super(key: key);

  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Colors.brown,
      elevation: 3.0,
      child: IconTheme.merge(
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          color: Colors.white,
        ),
      ),
    );
  }
}

dynamic displayDialog(context, String message) {
  showDialog(
    context: context,
    builder: (_) => SimpleDialog(
      title: Center(
        child: Text(
          message,
          style: TextStyle(
              fontFamily: kTitleFont,
              fontWeight: FontWeight.normal,
              fontSize: 14.0),
        ),
      ),
      children: <Widget>[
        SimpleDialogOption(
          child: Align(alignment: Alignment.center, child: Text("Dismiss")),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
