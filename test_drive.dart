import 'dart:io';

Future<void> main() async {
  var url = "https://drive.google.com/uc?export=download&id=17U3pk7CCLIytE8Hpp4CtaU4Nitj3V7wc";
  try {
    final client = HttpClient();
    
    for (int i = 0; i < 5; i++) {
      print('Requesting: $url');
      var request = await client.getUrl(Uri.parse(url));
      request.followRedirects = false; 
      var response = await request.close();
      print('Status: ${response.statusCode}');
      
      if (response.statusCode >= 300 && response.statusCode < 400) {
        var location = response.headers.value('location');
        if (location != null) {
          print('Redirect $i: $location');
          url = location;
        } else {
          break;
        }
      } else {
        print('Final URL: $url');
        break;
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
