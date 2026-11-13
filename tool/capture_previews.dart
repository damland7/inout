import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inout_app/app/app_routes.dart';
import 'package:inout_app/app/inout_app.dart';
import 'package:inout_app/preview/preview_services.dart';

final boundaryKey = GlobalKey();
Future<void> frame() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  await WidgetsBinding.instance.endOfFrame;
}

Future<void> capture(String route, String name) async {
  runApp(
    MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: RepaintBoundary(
        key: boundaryKey,
        child: InOutApp(
          key: ValueKey(name),
          services: createPreviewServices(today: DateTime(2026, 11, 7)),
          initialRoute: route,
        ),
      ),
    ),
  );
  await frame();
  WidgetsBinding.instance.renderViews.first.configuration =
      const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(width: 390, height: 844),
        physicalConstraints: BoxConstraints.tightFor(width: 780, height: 1688),
        devicePixelRatio: 2,
      );
  WidgetsBinding.instance.scheduleFrame();
  await frame();
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final output = Platform.environment['INOUT_PREVIEW_DIR'] ?? 'docs/previews';
  Directory(output).createSync(recursive: true);
  File('$output/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
  stdout.writeln('Captured $name');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var failed = false;
  FlutterError.onError = (error) {
    failed = true;
    stderr.writeln(error);
  };
  try {
    await capture(AppRoutes.history, 'history');
    await capture(AppRoutes.profile, 'profile');
    await capture(AppRoutes.editProfile, 'edit-profile');
    exit(failed ? 1 : 0);
  } catch (error, stack) {
    stderr.writeln(error);
    stderr.writeln(stack);
    exit(1);
  }
}
