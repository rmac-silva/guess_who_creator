import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkFooter extends StatelessWidget {
  final bool gamePage;

  const LinkFooter({super.key, required this.gamePage});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> footerButtons = [
      if (gamePage)
        TextButton.icon(
          label: const Text("Create Your Own Game!"),
          icon: const Icon(Icons.public_rounded),
          onPressed: () => _launchURL('https://guesswho.blazy.uk/#/home'),
        ),
      TextButton.icon(
        label: const Text("My Other Works"),
        icon: const Icon(Icons.terminal),
        onPressed: () => _launchURL('https://dev.blazy.uk'),
      ),
      TextButton.icon(
        label: const Text("Support me"),
        icon: const Icon(Icons.coffee),
        onPressed: () => _launchURL('https://ko-fi.com/rmacsilva'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < footerButtons.length; i++) ...[
            footerButtons[i],
            if (i < footerButtons.length - 1)
              const SizedBox(width: 16), // No spacing after the last item
          ],
        ],
      ),
    );
  }
}
