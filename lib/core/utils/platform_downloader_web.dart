// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadApk(String url, {String filename = 'synthera-prosthetic-hand.apk'}) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

void reloadPage() {
  html.window.location.reload();
}
