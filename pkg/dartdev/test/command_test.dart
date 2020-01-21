// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// TODO(jwren) move the following test utilities to a separate file

// Files that end in _test.dart must have a main method to satisfy the dart2js
// bots
void main() {
  test('empty test for dart2js', () {
    assert(true == true);
  });
}

TestProject project({String mainSrc}) => TestProject(mainSrc: mainSrc);

class TestProject {
  Directory dir;

  static String get defaultProjectName => 'dartdev_temp';

  String get name => defaultProjectName;

  TestProject({String mainSrc}) {
    dir = Directory.systemTemp.createTempSync('dartdev');
    if (mainSrc != null) {
      file('lib/main.dart', mainSrc);
    }
    file('pubspec.yaml', 'name: $name\ndev_dependencies:\n  test: any\n');
  }

  void file(String name, String contents) {
    var file = File(path.join(dir.path, name));
    file.parent.createSync();
    file.writeAsStringSync(contents);
  }

  void dispose() {
    dir.deleteSync(recursive: true);
  }

  ProcessResult run(String command, [List<String> args]) {
    var arguments = [
      path.absolute(path.join(Directory.current.path, 'bin', 'dartdev.dart')),
      command
    ];
    if (args != null && args.isNotEmpty) {
      arguments.addAll(args);
    }
    return Process.runSync(
      Platform.resolvedExecutable,
      arguments,
      workingDirectory: dir.path,
    );
  }

  File findFile(String name) {
    var file = File(path.join(dir.path, name));
    return file.existsSync() ? file : null;
  }
}
