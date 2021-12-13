import 'dart:core';


String getEmoticon(String emoticon) {
  if (emoticon == '😀') {
    return 'Happy';
  } else if (emoticon == '🥺') {
    return 'Sad';
  } else if (emoticon == '😩') {
    return 'Tired';
  } else if (emoticon == '😥') {
    return 'Worried';
  } else if (emoticon == 'Happy') {
    return '😀';
  } else if (emoticon == 'Sad') {
    return '🥺';
  } else if (emoticon == 'Tired') {
    return '😩';
  } else if (emoticon == 'Worried') {
    return '😥';
  }
}
