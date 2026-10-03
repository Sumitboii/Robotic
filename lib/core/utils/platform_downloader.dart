import 'platform_downloader_stub.dart'
    if (dart.library.html) 'platform_downloader_web.dart';

void triggerApkDownload(String url, {String filename = 'synthera-prosthetic-hand.apk'}) {
  downloadApk(url, filename: filename);
}

void triggerAppReload() {
  reloadPage();
}
