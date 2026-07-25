/// Ekstrak YouTube video ID dari berbagai format URL yang mungkin:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - https://www.youtube.com/embed/VIDEO_ID
/// - https://www.youtube.com/watch?v=VIDEO_ID&t=123s
///
/// Return null jika URL tidak dikenali.
String? extractYoutubeId(String url) {
  final regExp = RegExp(
    r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}
