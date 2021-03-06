// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/noop_service.dart';
import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:telemetry/crash_reporting.dart';

const _angularPluginName = 'Angular Analysis Plugin';

class CrashReportingInstrumentation extends NoopInstrumentationService {
  // A staging reporter, that we are in the process of phasing out.
  final CrashReportSender stagingReporter;

  // A prod reporter, that we are in the process of phasing in.
  final CrashReportSender prodReporter;

  // The angular plugin crash reporter.
  final CrashReportSender angularReporter;

  CrashReportingInstrumentation(
      this.stagingReporter, this.prodReporter, this.angularReporter);

  @override
  void logException(dynamic exception,
      [StackTrace stackTrace,
      List<InstrumentationServiceAttachment> attachments]) {
    var crashReportAttachments = (attachments ?? []).map((e) {
      return CrashReportAttachment.string(
        field: 'attachment_${e.id}',
        value: e.stringValue,
      );
    }).toList();

    if (exception is CaughtException) {
      // Get the root CaughtException, which matters most for debugging.
      var root = exception.rootCaughtException;

      _sendServerReport(root.exception, root.stackTrace,
          attachments: crashReportAttachments, comment: root.message);
    } else {
      _sendServerReport(exception, stackTrace ?? StackTrace.current,
          attachments: crashReportAttachments);
    }
  }

  @override
  void logPluginException(
    PluginData plugin,
    dynamic exception,
    StackTrace stackTrace,
  ) {
    if (plugin.name == _angularPluginName) {
      angularReporter.sendReport(exception, stackTrace).catchError((error) {
        // We silently ignore errors sending crash reports (network issues, ...).
      });
    } else {
      _sendServerReport(exception, stackTrace,
          comment: 'plugin: ${plugin.name}');
    }
  }

  void _sendServerReport(Object exception, Object stackTrace,
      {String comment, List<CrashReportAttachment> attachments}) {
    stagingReporter
        .sendReport(exception, stackTrace,
            attachments: attachments, comment: comment)
        .catchError((error) {
      // We silently ignore errors sending crash reports (network issues, ...).
    });
    prodReporter
        .sendReport(exception, stackTrace,
            attachments: attachments, comment: comment)
        .catchError((error) {
      // We silently ignore errors sending crash reports (network issues, ...).
    });
  }
}
