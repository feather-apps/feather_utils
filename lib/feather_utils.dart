import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

const MethodChannel _channel =
const MethodChannel('plugins.feather-apps.com/feather_utils');

void exitAndUpgradeFeatherApp() async {
  final id = await getFeatherAppId();
  final home = Platform.environment['HOME'];
  await Process.start(
      '$home/Library/Application Support/Feather Apps/App Launcher.app/Contents/MacOS/App Launcher',
      ['-id', id],
      mode: ProcessStartMode.detached);
  exit(0);
}

Future<String> getFeatherAppId() async {
  return await _channel.invokeMethod('getAppId');
}

Future<String> getFeatherAppVersion() async {
  return await _channel.invokeMethod('getAppVersion');
}

Future<String> getFeatherAgent() async {
  return await _channel.invokeMethod('getAgentId');
}


void checkForNewVersion(Function newVersionCallback) async {
  final id = await getFeatherAppId();
  final vers = await getFeatherAppVersion();
  final agent = await getFeatherAgent();
  print('**** sending agent id = $agent');

  // await Future.delayed(const Duration(seconds: 1));

  final client = Client();
  try {
    final url = 'https://localhost:8443/FeatherApps/VersionCheck'
        '?feather-app-id=$id&feather-app-version=$vers&feather-agent-id=$agent';
    final response = await client.get(url);
    if (response.statusCode == HttpStatus.upgradeRequired) {
      newVersionCallback();
    }
  }
  finally {
    client.close();
  }

}

const Color _kSnackBackground = Color(0xFF323232);

/// A widget that checks whether an upgrade is available.  If it is, this
/// widget will show a message prompting the user to upgrade.  This widget
/// is designed to be used as the body of a [Scaffold]
class VersionCheck extends StatefulWidget {
  /// The child of this widget
  final Widget child;

  /// The icon to show the user when an upgrade is available
  final IconData icon;

  /// The message to show the user when an upgrade is available
  final String upgradeMessage;

  /// The label of the button to initiate an upgrade
  final String upgradeAction;

  /// The label of the button to dismiss the upgrade message
  final String dismissAction;

  @override
  _VersionCheckState createState() => _VersionCheckState();

  VersionCheck(
      {@required this.child,
        this.icon,
        this.upgradeMessage,
        this.upgradeAction,
        this.dismissAction});
}

class _VersionCheckState extends State<VersionCheck> {
  @override
  void initState() {
    super.initState();
    checkForNewVersion(_promptUpgrade);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  _promptUpgrade() {
    showBottomSheet<void>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final darkTheme = new ThemeData(
            brightness: Brightness.dark,
            accentColor: theme.accentColor,
            accentColorBrightness: theme.accentColorBrightness,
          );
          return new Material(
            elevation: 6.0,
            color: _kSnackBackground,
            child: new Theme(
              data: darkTheme,
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
                    child: new Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: new Icon(widget.icon ?? Icons.info),
                        ),
                        new Text(
                          widget.upgradeMessage ??
                              'A new version of this app is available',
                          style: darkTheme.textTheme.subhead
                              .copyWith(fontSize: 16.0),
                        )
                      ],
                    ),
                  ),
                  new ButtonTheme.bar(
                    child: new ButtonBar(
                      children: <Widget>[
                        FlatButton(
                            child:
                            new Text(widget.upgradeAction ?? 'UPDATE NOW'),
                            onPressed: exitAndUpgradeFeatherApp),
                        FlatButton(
                            child: new Text(widget.dismissAction ?? 'DISMISS'),
                            onPressed: () => Navigator.of(context).pop())
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
