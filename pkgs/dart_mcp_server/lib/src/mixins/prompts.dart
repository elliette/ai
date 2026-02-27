// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:meta/meta.dart';

import '../features_configuration.dart';
import '../utils/names.dart';

/// A mixin which adds support for various dart and flutter specific prompts.
base mixin DashPrompts on PromptsSupport {
  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    addPrompt(flutterDriverUserJourneyTest, _flutterDriverUserJourneyPrompt);
    addPrompt(capturePerformanceSnapshot, _capturePerformanceSnapshotPrompt);
    return super.initialize(request);
  }

  static final allPrompts = [
    flutterDriverUserJourneyTest,
    capturePerformanceSnapshot,
  ];

  /// Creates the flutter driver user journey prompt based on a request.
  GetPromptResult _flutterDriverUserJourneyPrompt(GetPromptRequest request) {
    final userJourney =
        request.arguments?[ParameterNames.userJourney] as String?;
    return GetPromptResult(
      messages: [
        PromptMessage(
          role: Role.user,
          content: flutterDriverUserJourneyPromptContent,
        ),
        if (userJourney != null)
          PromptMessage(
            role: Role.user,
            content: Content.text(text: 'The user journey is:\n$userJourney'),
          ),
      ],
    );
  }

  /// Creates the capture performance snapshot prompt.
  GetPromptResult _capturePerformanceSnapshotPrompt(GetPromptRequest request) {
    return GetPromptResult(
      messages: [
        PromptMessage(
          role: Role.user,
          content: capturePerformanceSnapshotPromptContent,
        ),
      ],
    );
  }

  @visibleForTesting
  static final capturePerformanceSnapshot = Prompt(
    name: PromptNames.capturePerformanceSnapshot.name,
    title: 'Capture Performance Snapshot',
    description: '''
Prompts the LLM to capture a performance snapshot using DevTools.
''',
  )..categories = [FeatureCategory.performance];

  @visibleForTesting
  static final flutterDriverUserJourneyTest = Prompt(
    name: PromptNames.flutterDriverUserJourneyTest.name,
    title: 'User journey flutter driver test',
    description: '''
Prompts the LLM to attempt to accomplish a user journey in the running app using
flutter driver. If successful, it will then translate the steps it followed into
a flutter driver test and write that to disk.
''',
    arguments: [
      PromptArgument(
        name: ParameterNames.userJourney,
        title: 'User Journey',
        description: 'The user journey to perform and write a test for.',
        required: false,
      ),
    ],
  )..categories = [FeatureCategory.flutterDriver];

  @visibleForTesting
  static final capturePerformanceSnapshotPromptContent = Content.text(
    text: '''
Perform the following tasks in order:

1. Connect to the Dart Tooling Daemon (DTD) using the `connect_dart_tooling_daemon` tool.
2. Prompt the user to open the DevTools in a browser, and wait for them to confirm they have done so.
3. Switch to the performance screen using the `switch_dev_tools_screen` tool with `screenId` set to `performance`.
4. Prompt the user to interact with their app for 10 seconds to generate performance data. Ask them to confirm when they start interacting.
5. Wait 10 seconds, then capture a screenshot of the performance screen using the `devtools_screenshot` tool with `screenId` set to `performance`.
''',
  );

  @visibleForTesting
  static final flutterDriverUserJourneyPromptContent = Content.text(
    text: '''
Perform the following tasks in order:

- Prompt the user to navigate to the home page of the app.
- Prompt the user for a user journey that they would like to write a test for.
- Attempt to complete the given user journey using flutter driver to inspect the
  widget tree and interact with the application. Only durable interactions
  should be performed, do not use temporary IDs to select or interact with
  widgets, but instead select them based on text, type, tooltip, etc. Avoid
  reading in files to accomplish this task, just inspect the live state of the
  app and widget tree. If you get stuck, feel free to ask the user for help.
  ALWAYS get the widget tree after performing any interaction, so you can see
  the updated state of the app.
- If you are able to successfully complete the journey, then create a flutter
  driver based test with an appropriate name under the integration_test
  directory. The test should perform all the successful actions that you
  performed to complete the task and validate the result. Include the
  original user journey as a comment above the test function, or reference the
  file the user journey is defined in if it came from a file. Note that
  flutter_driver tests are NOT allowed to import package:flutter_test, they MUST
  use package:test. Importing package:flutter_test will cause very confusing
  errors and waste my time. Also, when creating variables that you will assign
  in a setUp or setUpAll function, they must be late (preferred) or nullable.
- After writing the test, first analyze the project for errors, and format it.
- Next, execute the test using the command `flutter drive --driver <test-path>`
  and verify that it passes.
''',
  );
}
