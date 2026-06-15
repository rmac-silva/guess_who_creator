import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkFooter extends StatelessWidget {

  const LinkFooter({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(label: const Text("Devpage"), icon: const Icon(Icons.terminal), onPressed: () => _launchURL('https://dev.blazy.uk'),),
          SizedBox(width: 32),
                    TextButton.icon(label: const Text("Support me"), icon: const Icon(Icons.coffee), onPressed: () => _launchURL('https://ko-fi.com/rmacsilva'),),

        ],
      ),
    );
  }
}
