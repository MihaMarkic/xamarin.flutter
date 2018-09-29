// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph, Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_canvas.dart';

/// Matches objects or functions that paint a display list that matches the
/// canvas calls described by the pattern.
///
/// Specifically, this can be applied to [RenderObject]s, [Finder]s that
/// correspond to a single [RenderObject], and functions that have either of the
/// following signatures:
///
/// ```dart
/// void function(PaintingContext context, Offset offset);
/// void function(Canvas canvas);
/// ```
///
/// In the case of functions that take a [PaintingContext] and an [Offset], the
/// [paints] matcher will always pass a zero offset.
///
/// To specify the pattern, call the methods on the returned object. For example:
///
/// ```dart
///  expect(myRenderObject, paints..circle(radius: 10.0)..circle(radius: 20.0));
/// ```
///
/// This particular pattern would verify that the render object `myRenderObject`
/// paints, among other things, two circles of radius 10.0 and 20.0 (in that
/// order).
///
/// See [PaintPattern] for a discussion of the semantics of paint patterns.
///
/// To match something which paints nothing, see [paintsNothing].
///
/// To match something which asserts instead of painting, see [paintsAssertion].
PaintPattern get paints => new _TestRecordingCanvasPatternMatcher();

/// Matches objects or functions that does not paint anything on the canvas.
Matcher get paintsNothing => new _TestRecordingCanvasPaintsNothingMatcher();

/// Matches objects or functions that assert when they try to paint.
Matcher get paintsAssertion => new _TestRecordingCanvasPaintsAssertionMatcher();

/// Signature for [PaintPattern.something] predicate argument.
///
/// Used by the [paints] matcher.
///
/// The `methodName` argument is a [Symbol], and can be compared with the symbol
/// literal syntax, for example:
///
/// ```dart
/// if (methodName == #drawCircle) { ... }
/// ```
typedef bool PaintPatternPredicate(Symbol methodName, List<dynamic> arguments);

/// The signature of [RenderObject.paint] functions.
typedef void _ContextPainterFunction(PaintingContext context, Offset offset);

/// The signature of functions that paint directly on a canvas.
typedef void _CanvasPainterFunction(Canvas canvas);

/// Builder interface for patterns used to match display lists (canvas calls).
///
/// The [paints] matcher returns a [PaintPattern] so that you can build the
/// pattern in the [expect] call.
///
/// Patterns are subset matches, meaning that any calls not described by the
/// pattern are ignored. This allows, for instance, transforms to be skipped.
abstract class PaintPattern {
  /// Indicates that a transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.transform] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.transform] is found, then the matcher fails.
  ///
  /// Dynamic so matchers can be more easily passed in.
  ///
  /// The `matrix4` argument is dynamic so it can be either a [Matcher], or a
  /// [Float64List] of [double]s. If it is a [Float64List] of [double]s then
  /// each value in the matrix must match in the expected matrix. A deep
  /// matching [Matcher] such as [equals] can be used to test each value in the
  /// matrix with utilities such as [moreOrLessEquals].
  void transform({ dynamic matrix4 });

  /// Indicates that a translation transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.translate] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.translate] is found, then the matcher fails.
  void translate({ double x, double y });

  /// Indicates that a scale transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.scale] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.scale] is found, then the matcher fails.
  void scale({ double x, double y });

  /// Indicates that a rotate transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.rotate] is found. If the `angle`
  /// argument is provided here, the call's argument is compared to it. If that
  /// fails to match, or if no call to [Canvas.rotate] is found, then the
  /// matcher fails.
  void rotate({ double angle });

  /// Indicates that a save is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [restore], [saveRestore].
  void save();

  /// Indicates that a restore is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.restore] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [save], [saveRestore].
  void restore();

  /// Indicates that a matching pair of save/restore calls is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found, then, calls are
  /// skipped until the matching [Canvas.restore] call is found. If no matching
  /// pair of calls could be found, the matcher fails.
  ///
  /// See also: [save], [restore].
  void saveRestore();

  /// Indicates that a rectangular clip is expected next.
  ///
  /// The next rectangular clip is examined. Any arguments that are passed to
  /// this method are compared to the actual [Canvas.clipRect] call's argument
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.clipRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.clipRect] call are ignored.
  void clipRect({ Rect rect });

  /// Indicates that a path clip is expected next.
  ///
  /// The next path clip is examined.
  /// The path that is passed to the actual [Canvas.clipPath] call is matched
  /// using [pathMatcher].
  ///
  /// If no call to [Canvas.clipPath] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.clipPath] call are ignored.
  void clipPath({Matcher pathMatcher});

  /// Indicates that a rectangle is expected next.
  ///
  /// The next rectangle is examined. Any arguments that are passed to this
  /// method are compared to the actual [Canvas.drawRect] call's arguments
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void rect({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a rounded rectangle clip is expected next.
  ///
  /// The next rounded rectangle clip is examined. Any arguments that are passed
  /// to this method are compared to the actual [Canvas.clipRRect] call's
  /// argument and any mismatches result in failure.
  ///
  /// If no call to [Canvas.clipRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.clipRRect] call are ignored.
  void clipRRect({ RRect rrect });

  /// Indicates that a rounded rectangle is expected next.
  ///
  /// The next rounded rectangle is examined. Any arguments that are passed to
  /// this method are compared to the actual [Canvas.drawRRect] call's arguments
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void rrect({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a rounded rectangle outline is expected next.
  ///
  /// The next call to [Canvas.drawRRect] is examined. Any arguments that are
  /// passed to this method are compared to the actual [Canvas.drawRRect] call's
  /// arguments and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void drrect({ RRect outer, RRect inner, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a circle is expected next.
  ///
  /// The next circle is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawCircle] call's arguments and any
  /// mismatches result in failure.
  ///
  /// If no call to [Canvas.drawCircle] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawCircle] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void circle({ double x, double y, double radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a path is expected next.
  ///
  /// The next path is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawPath] call's `paint` argument, and
  /// any mismatches result in failure.
  ///
  /// To introspect the Path object (as it stands after the painting has
  /// completed), the `includes` and `excludes` arguments can be provided to
  /// specify points that should be considered inside or outside the path
  /// (respectively).
  ///
  /// If no call to [Canvas.drawPath] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawPath] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void path({ Iterable<Offset> includes, Iterable<Offset> excludes, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a line is expected next.
  ///
  /// The next line is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawLine] call's `p1`, `p2`, and
  /// `paint` arguments, and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawLine] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawLine] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void line({ Offset p1, Offset p2, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that an arc is expected next.
  ///
  /// The next arc is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawArc] call's `paint` argument, and
  /// any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawArc] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawArc] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void arc({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a paragraph is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.drawParagraph] is found. Any
  /// arguments that are passed to this method are compared to the actual
  /// [Canvas.drawParagraph] call's argument, and any mismatches result in failure.
  ///
  /// The `offset` argument can be either an [Offset] or a [Matcher]. If it is
  /// an [Offset] then the actual value must match the expected offset
  /// precisely. If it is a [Matcher] then the comparison is made according to
  /// the semantics of the [Matcher]. For example, [within] can be used to
  /// assert that the actual offset is within a given distance from the expected
  /// offset.
  ///
  /// If no call to [Canvas.drawParagraph] was made, then this results in failure.
  void paragraph({ ui.Paragraph paragraph, dynamic offset });

  /// Indicates that a shadow is expected next.
  ///
  /// The next shadow is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawShadow] call's `paint` argument,
  /// and any mismatches result in failure.
  ///
  /// In tests, shadows from framework features such as [BoxShadow] or
  /// [Material] are disabled by default, and thus this predicate would not
  /// match. The [debugDisableShadows] flag controls this.
  ///
  /// To introspect the Path object (as it stands after the painting has
  /// completed), the `includes` and `excludes` arguments can be provided to
  /// specify points that should be considered inside or outside the path
  /// (respectively).
  ///
  /// If no call to [Canvas.drawShadow] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawShadow] call are ignored.
  void shadow({ Iterable<Offset> includes, Iterable<Offset> excludes, Color color, double elevation, bool transparentOccluder });

  /// Indicates that an image is expected next.
  ///
  /// The next call to [Canvas.drawImage] is examined, and its arguments
  /// compared to those passed to _this_ method.
  ///
  /// If no call to [Canvas.drawImage] was made, then this results in
  /// failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawImage] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void image({ ui.Image image, double x, double y, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that an image subsection is expected next.
  ///
  /// The next call to [Canvas.drawImageRect] is examined, and its arguments
  /// compared to those passed to _this_ method.
  ///
  /// If no call to [Canvas.drawImageRect] was made, then this results in
  /// failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawImageRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void drawImageRect({ ui.Image image, Rect source, Rect destination, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Provides a custom matcher.
  ///
  /// Each method call after the last matched call (if any) will be passed to
  /// the given predicate, along with the values of its (positional) arguments.
  ///
  /// For each one, the predicate must either return a boolean or throw a [String].
  ///
  /// If the predicate returns true, the call is considered a successful match
  /// and the next step in the pattern is examined. If this was the last step,
  /// then any calls that were not yet matched are ignored and the [paints]
  /// [Matcher] is considered a success.
  ///
  /// If the predicate returns false, then the call is considered uninteresting
  /// and the predicate will be called again for the next [Canvas] call that was
  /// made by the [RenderObject] under test. If this was the last call, then the
  /// [paints] [Matcher] is considered to have failed.
  ///
  /// If the predicate throws a [String], then the [paints] [Matcher] is
  /// considered to have failed. The thrown string is used in the message
  /// displayed from the test framework and should be complete sentence
  /// describing the problem.
  void something(PaintPatternPredicate predicate);
}

/// Matches a [Path] that contains (as defined by [Path.contains]) the given
/// `includes` points and does not contain the given `excludes` points.
Matcher isPathThat({
  Iterable<Offset> includes: const <Offset>[],
  Iterable<Offset> excludes: const <Offset>[],
}) {
  return new _PathMatcher(includes.toList(), excludes.toList());
}

class _PathMatcher extends Matcher {
  _PathMatcher(this.includes, this.excludes);

  List<Offset> includes;
  List<Offset> excludes;

  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    if (object is! Path) {
      matchState[this] = 'The given object ($object) was not a Path.';
      return false;
    }
    final Path path = object;
    final List<String> errors = <String>[];
    for (Offset offset in includes) {
      if (!path.contains(offset))
        errors.add('Offset $offset should be inside the path, but is not.');
    }
    for (Offset offset in excludes) {
      if (path.contains(offset))
        errors.add('Offset $offset should be outside the path, but is not.');
    }
    if (errors.isEmpty)
      return true;
    matchState[this] = 'Not all the given points were inside or outside the path as expected:\n  ${errors.join("\n  ")}';
    return false;
  }

  @override
  Description describe(Description description) {
    String points(List<Offset> list) {
      final int count = list.length;
      if (count == 1)
        return 'one particular point';
      return '$count particular points';
    }
    return description.add('A Path that contains ${points(includes)} but does not contain ${points(excludes)}.');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add(matchState[this]);
  }
}

class _MismatchedCall {
  const _MismatchedCall(this.message, this.callIntroduction, this.call) : assert(call != null);
  final String message;
  final String callIntroduction;
  final RecordedInvocation call;
}

bool _evaluatePainter(Object object, Canvas canvas, PaintingContext context) {
  if (object is _ContextPainterFunction) {
    final _ContextPainterFunction function = object;
    function(context, Offset.zero);
  } else if (object is _CanvasPainterFunction) {
    final _CanvasPainterFunction function = object;
    function(canvas);
  } else {
    if (object is Finder) {
      TestAsyncUtils.guardSync();
      final Finder finder = object;
      object = finder.evaluate().single.renderObject;
    }
    if (object is RenderObject) {
      final RenderObject renderObject = object;
      renderObject.paint(context, Offset.zero);
    } else {
      return false;
    }
  }
  return true;
}

abstract class _TestRecordingCanvasMatcher extends Matcher {
  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    final TestRecordingCanvas canvas = new TestRecordingCanvas();
    final TestRecordingPaintingContext context = new TestRecordingPaintingContext(canvas);
    final StringBuffer description = new StringBuffer();
    String prefixMessage = 'unexpectedly failed.';
    bool result = false;
    try {
      if (!_evaluatePainter(object, canvas, context)) {
        matchState[this] = 'was not one of the supported objects for the "paints" matcher.';
        return false;
      }
      result = _evaluatePredicates(canvas.invocations, description);
      if (!result)
        prefixMessage = 'did not match the pattern.';
    } catch (error, stack) {
      prefixMessage = 'threw the following exception:';
      description.writeln(error.toString());
      description.write(stack.toString());
      result = false;
    }
    if (!result) {
      if (canvas.invocations.isNotEmpty) {
        description.write('The complete display list was:');
        for (RecordedInvocation call in canvas.invocations)
          description.write('\n  * $call');
      }
      matchState[this] = '$prefixMessage\n$description';
    }
    return result;
  }

  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add(matchState[this]);
  }
}

class _TestRecordingCanvasPaintsNothingMatcher extends _TestRecordingCanvasMatcher {
  @override
  Description describe(Description description) {
    return description.add('An object or closure that paints nothing.');
  }

  @override
  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description) {
    final Iterable<RecordedInvocation> paintingCalls = _filterCanvasCalls(calls);
    if (paintingCalls.isEmpty)
      return true;
    description.write(
      'painted something, the first call having the following stack:\n'
      '${paintingCalls.first.stackToString(indent: "  ")}\n'
    );
    return false;
  }

  static const List<Symbol> _nonPaintingOperations = const <Symbol> [
    #save,
    #restore,
  ];

  // Filters out canvas calls that are not painting anything.
  static Iterable<RecordedInvocation> _filterCanvasCalls(Iterable<RecordedInvocation> canvasCalls) {
    return canvasCalls.where((RecordedInvocation canvasCall) =>
      !_nonPaintingOperations.contains(canvasCall.invocation.memberName)
    );
  }
}

class _TestRecordingCanvasPaintsAssertionMatcher extends Matcher {
  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    final TestRecordingCanvas canvas = new TestRecordingCanvas();
    final TestRecordingPaintingContext context = new TestRecordingPaintingContext(canvas);
    final StringBuffer description = new StringBuffer();
    String prefixMessage = 'unexpectedly failed.';
    bool result = false;
    try {
      if (!_evaluatePainter(object, canvas, context)) {
        matchState[this] = 'was not one of the supported objects for the "paints" matcher.';
        return false;
      }
      prefixMessage = 'did not assert.';
    } on AssertionError {
      result = true;
    } catch (error, stack) {
      prefixMessage = 'threw the following exception:';
      description.writeln(error.toString());
      description.write(stack.toString());
      result = false;
    }
    if (!result) {
      if (canvas.invocations.isNotEmpty) {
        description.write('The complete display list was:');
        for (RecordedInvocation call in canvas.invocations)
          description.write('\n  * $call');
      }
      matchState[this] = '$prefixMessage\n$description';
    }
    return result;
  }

  @override
  Description describe(Description description) {
    return description.add('An object or closure that asserts when it tries to paint.');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add(matchState[this]);
  }
}

class _TestRecordingCanvasPatternMatcher extends _TestRecordingCanvasMatcher implements PaintPattern {
  final List<_PaintPredicate> _predicates = <_PaintPredicate>[];

  @override
  void transform({ dynamic matrix4 }) {
    _predicates.add(new _FunctionPaintPredicate(#transform, <dynamic>[matrix4]));
  }

  @override
  void translate({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#translate, <dynamic>[x, y]));
  }

  @override
  void scale({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#scale, <dynamic>[x, y]));
  }

  @override
  void rotate({ double angle }) {
    _predicates.add(new _FunctionPaintPredicate(#rotate, <dynamic>[angle]));
  }

  @override
  void save() {
    _predicates.add(new _FunctionPaintPredicate(#save, <dynamic>[]));
  }

  @override
  void restore() {
    _predicates.add(new _FunctionPaintPredicate(#restore, <dynamic>[]));
  }

  @override
  void saveRestore() {
    _predicates.add(new _SaveRestorePairPaintPredicate());
  }

  @override
  void clipRect({ Rect rect }) {
    _predicates.add(new _FunctionPaintPredicate(#clipRect, <dynamic>[rect]));
  }

  @override
  void clipPath({Matcher pathMatcher}) {
    _predicates.add(new _FunctionPaintPredicate(#clipPath, <dynamic>[pathMatcher]));
  }

  @override
  void rect({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _RectPaintPredicate(rect: rect, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void clipRRect({ RRect rrect }) {
    _predicates.add(new _FunctionPaintPredicate(#clipRRect, <dynamic>[rrect]));
  }

  @override
  void rrect({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _RRectPaintPredicate(rrect: rrect, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void drrect({ RRect outer, RRect inner, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _DRRectPaintPredicate(outer: outer, inner: inner, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void circle({ double x, double y, double radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _CirclePaintPredicate(x: x, y: y, radius: radius, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void path({ Iterable<Offset> includes, Iterable<Offset> excludes, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _PathPaintPredicate(includes: includes, excludes: excludes, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void line({ Offset p1, Offset p2, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _LinePaintPredicate(p1: p1, p2: p2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void arc({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _ArcPaintPredicate(color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void paragraph({ ui.Paragraph paragraph, dynamic offset }) {
    _predicates.add(new _FunctionPaintPredicate(#drawParagraph, <dynamic>[paragraph, offset]));
  }

  @override
  void shadow({ Iterable<Offset> includes, Iterable<Offset> excludes, Color color, double elevation, bool transparentOccluder }) {
    _predicates.add(new _ShadowPredicate(includes: includes, excludes: excludes, color: color, elevation: elevation, transparentOccluder: transparentOccluder));
  }

  @override
  void image({ ui.Image image, double x, double y, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _DrawImagePaintPredicate(image: image, x: x, y: y, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void drawImageRect({ ui.Image image, Rect source, Rect destination, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _DrawImageRectPaintPredicate(image: image, source: source, destination: destination, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void something(PaintPatternPredicate predicate) {
    _predicates.add(new _SomethingPaintPredicate(predicate));
  }

  @override
  Description describe(Description description) {
    if (_predicates.isEmpty)
      return description.add('An object or closure and a paint pattern.');
    description.add('Object or closure painting: ');
    return description.addAll(
      '', ', ', '',
      _predicates.map<String>((_PaintPredicate predicate) => predicate.toString()),
    );
  }

  @override
  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description) {
    if (calls.isEmpty) {
      description.writeln('It painted nothing.');
      return false;
    }
    if (_predicates.isEmpty) {
      description.writeln(
        'It painted something, but you must now add a pattern to the paints matcher '
        'in the test to verify that it matches the important parts of the following.'
      );
      return false;
    }
    final Iterator<_PaintPredicate> predicate = _predicates.iterator;
    final Iterator<RecordedInvocation> call = calls.iterator..moveNext();
    try {
      while (predicate.moveNext()) {
        if (call.current == null) {
          throw 'It painted less on its canvas than the paint pattern expected. '
                'The first missing paint call was: ${predicate.current}';
        }
        predicate.current.match(call);
      }
      assert(predicate.current == null);
      // We allow painting more than expected.
    } on _MismatchedCall catch (data) {
      description.writeln(data.message);
      description.writeln(data.callIntroduction);
      description.writeln(data.call.stackToString(indent: '  '));
      return false;
    } on String catch (s) {
      description.writeln(s);
      if (call.current != null) {
        description.write('The stack of the offending call was:\n${call.current.stackToString(indent: "  ")}\n');
      } else {
        description.write('The stack of the first call was:\n${calls.first.stackToString(indent: "  ")}\n');
      }
      return false;
    }
    return true;
  }
}

abstract class _PaintPredicate {
  void match(Iterator<RecordedInvocation> call);

  @protected
  void checkMethod(Iterator<RecordedInvocation> call, Symbol symbol) {
    int others = 0;
    final RecordedInvocation firstCall = call.current;
    while (!call.current.invocation.isMethod || call.current.invocation.memberName != symbol) {
      others += 1;
      if (!call.moveNext())
        throw new _MismatchedCall(
          'It called $others other method${ others == 1 ? "" : "s" } on the canvas, '
          'the first of which was $firstCall, but did not '
          'call ${_symbolName(symbol)}() at the time where $this was expected.',
          'The first method that was called when the call to ${_symbolName(symbol)}() '
          'was expected, $firstCall, was called with the following stack:',
          firstCall,
        );
    }
  }

  @override
  String toString() {
    throw new FlutterError('$runtimeType does not implement toString.');
  }
}

abstract class _DrawCommandPaintPredicate extends _PaintPredicate {
  _DrawCommandPaintPredicate(
    this.symbol, this.name, this.argumentCount, this.paintArgumentIndex,
    { this.color, this.strokeWidth, this.hasMaskFilter, this.style }
  );

  final Symbol symbol;
  final String name;
  final int argumentCount;
  final int paintArgumentIndex;
  final Color color;
  final double strokeWidth;
  final bool hasMaskFilter;
  final PaintingStyle style;

  String get methodName => _symbolName(symbol);

  @override
  void match(Iterator<RecordedInvocation> call) {
    checkMethod(call, symbol);
    final int actualArgumentCount = call.current.invocation.positionalArguments.length;
    if (actualArgumentCount != argumentCount)
      throw 'It called $methodName with $actualArgumentCount argument${actualArgumentCount == 1 ? "" : "s"}; expected $argumentCount.';
    verifyArguments(call.current.invocation.positionalArguments);
    call.moveNext();
  }

  @protected
  @mustCallSuper
  void verifyArguments(List<dynamic> arguments) {
    final Paint paintArgument = arguments[paintArgumentIndex];
    if (color != null && paintArgument.color != color)
      throw 'It called $methodName with a paint whose color, ${paintArgument.color}, was not exactly the expected color ($color).';
    if (strokeWidth != null && paintArgument.strokeWidth != strokeWidth)
      throw 'It called $methodName with a paint whose strokeWidth, ${paintArgument.strokeWidth}, was not exactly the expected strokeWidth ($strokeWidth).';
    if (hasMaskFilter != null && (paintArgument.maskFilter != null) != hasMaskFilter) {
      if (hasMaskFilter)
        throw 'It called $methodName with a paint that did not have a mask filter, despite expecting one.';
      else
        throw 'It called $methodName with a paint that did have a mask filter, despite not expecting one.';
    }
    if (style != null && paintArgument.style != style)
      throw 'It called $methodName with a paint whose style, ${paintArgument.style}, was not exactly the expected style ($style).';
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    String result = name;
    if (description.isNotEmpty)
      result += ' with ${description.join(", ")}';
    return result;
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (color != null)
      description.add('$color');
    if (strokeWidth != null)
      description.add('strokeWidth: $strokeWidth');
    if (hasMaskFilter != null)
      description.add(hasMaskFilter ? 'a mask filter' : 'no mask filter');
    if (style != null)
      description.add('$style');
  }
}

class _OneParameterPaintPredicate<T> extends _DrawCommandPaintPredicate {
  _OneParameterPaintPredicate(Symbol symbol, String name, {
    @required this.expected,
    @required Color color,
    @required double strokeWidth,
    @required bool hasMaskFilter,
    @required PaintingStyle style
  }) : super(
    symbol, name, 2, 1, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style);

  final T expected;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final T actual = arguments[0];
    if (expected != null && actual != expected)
      throw 'It called $methodName with $T, $actual, which was not exactly the expected $T ($expected).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (expected != null) {
      if (expected.toString().contains(T.toString())) {
        description.add('$expected');
      } else {
        description.add('$T: $expected');
      }
    }
  }
}

class _TwoParameterPaintPredicate<T1, T2> extends _DrawCommandPaintPredicate {
  _TwoParameterPaintPredicate(Symbol symbol, String name, {
    @required this.expected1,
    @required this.expected2,
    @required Color color,
    @required double strokeWidth,
    @required bool hasMaskFilter,
    @required PaintingStyle style
  }) : super(
    symbol, name, 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style);

  final T1 expected1;

  final T2 expected2;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final T1 actual1 = arguments[0];
    if (expected1 != null && actual1 != expected1)
      throw 'It called $methodName with its first argument (a $T1), $actual1, which was not exactly the expected $T1 ($expected1).';
    final T2 actual2 = arguments[1];
    if (expected2 != null && actual2 != expected2)
      throw 'It called $methodName with its second argument (a $T2), $actual2, which was not exactly the expected $T2 ($expected2).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (expected1 != null) {
      if (expected1.toString().contains(T1.toString())) {
        description.add('$expected1');
      } else {
        description.add('$T1: $expected1');
      }
    }
    if (expected2 != null) {
      if (expected2.toString().contains(T2.toString())) {
        description.add('$expected2');
      } else {
        description.add('$T2: $expected2');
      }
    }
  }
}

class _RectPaintPredicate extends _OneParameterPaintPredicate<Rect> {
  _RectPaintPredicate({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawRect,
    'a rectangle',
    expected: rect,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _RRectPaintPredicate extends _OneParameterPaintPredicate<RRect> {
  _RRectPaintPredicate({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawRRect,
    'a rounded rectangle',
    expected: rrect,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _DRRectPaintPredicate extends _TwoParameterPaintPredicate<RRect, RRect> {
  _DRRectPaintPredicate({ RRect inner, RRect outer, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawDRRect,
    'a rounded rectangle outline',
    expected1: outer,
    expected2: inner,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _CirclePaintPredicate extends _DrawCommandPaintPredicate {
  _CirclePaintPredicate({ this.x, this.y, this.radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawCircle, 'a circle', 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final double x;
  final double y;
  final double radius;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final Offset pointArgument = arguments[0];
    if (x != null && y != null) {
      final Offset point = new Offset(x, y);
      if (point != pointArgument)
        throw 'It called $methodName with a center coordinate, $pointArgument, which was not exactly the expected coordinate ($point).';
    } else {
      if (x != null && pointArgument.dx != x)
        throw 'It called $methodName with a center coordinate, $pointArgument, whose x-coordinate not exactly the expected coordinate (${x.toStringAsFixed(1)}).';
      if (y != null && pointArgument.dy != y)
        throw 'It called $methodName with a center coordinate, $pointArgument, whose y-coordinate not exactly the expected coordinate (${y.toStringAsFixed(1)}).';
    }
    final double radiusArgument = arguments[1];
    if (radius != null && radiusArgument != radius)
      throw 'It called $methodName with radius, ${radiusArgument.toStringAsFixed(1)}, which was not exactly the expected radius (${radius.toStringAsFixed(1)}).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (x != null && y != null) {
      description.add('point ${new Offset(x, y)}');
    } else {
      if (x != null)
        description.add('x-coordinate ${x.toStringAsFixed(1)}');
      if (y != null)
        description.add('y-coordinate ${y.toStringAsFixed(1)}');
    }
    if (radius != null)
      description.add('radius ${radius.toStringAsFixed(1)}');
  }
}

class _PathPaintPredicate extends _DrawCommandPaintPredicate {
  _PathPaintPredicate({ this.includes, this.excludes, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawPath, 'a path', 2, 1, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final Iterable<Offset> includes;
  final Iterable<Offset> excludes;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final Path pathArgument = arguments[0];
    if (includes != null) {
      for (Offset offset in includes) {
        if (!pathArgument.contains(offset))
          throw 'It called $methodName with a path that unexpectedly did not contain $offset.';
      }
    }
    if (excludes != null) {
      for (Offset offset in excludes) {
        if (pathArgument.contains(offset))
          throw 'It called $methodName with a path that unexpectedly contained $offset.';
      }
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (includes != null && excludes != null) {
      description.add('that contains $includes and does not contain $excludes');
    } else if (includes != null) {
      description.add('that contains $includes');
    } else if (excludes != null) {
      description.add('that does not contain $excludes');
    }
  }
}

// TODO(ianh): add arguments to test the length, angle, that kind of thing
class _LinePaintPredicate extends _DrawCommandPaintPredicate {
  _LinePaintPredicate({ this.p1, this.p2, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawLine, 'a line', 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final Offset p1;
  final Offset p2;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments); // Checks the 3rd argument, a Paint
    if (arguments.length != 3)
      throw 'It called $methodName with ${arguments.length} arguments; expected 3.';
    final Offset p1Argument = arguments[0];
    final Offset p2Argument = arguments[1];
    if (p1 != null && p1Argument != p1) {
        throw 'It called $methodName with p1 endpoint, $p1Argument, which was not exactly the expected endpoint ($p1).';
    }
    if (p2 != null && p2Argument != p2) {
        throw 'It called $methodName with p2 endpoint, $p2Argument, which was not exactly the expected endpoint ($p2).';
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (p1 != null)
      description.add('end point p1: $p1');
    if (p2 != null)
      description.add('end point p2: $p2');
  }
}

class _ArcPaintPredicate extends _DrawCommandPaintPredicate {
  _ArcPaintPredicate({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawArc, 'an arc', 5, 4, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );
}

class _ShadowPredicate extends _PaintPredicate {
  _ShadowPredicate({ this.includes, this.excludes, this.color, this.elevation, this.transparentOccluder });

  final Iterable<Offset> includes;
  final Iterable<Offset> excludes;
  final Color color;
  final double elevation;
  final bool transparentOccluder;

  static const Symbol symbol = #drawShadow;
  String get methodName => _symbolName(symbol);

  @protected
  void verifyArguments(List<dynamic> arguments) {
    if (arguments.length != 4)
      throw 'It called $methodName with ${arguments.length} arguments; expected 4.';
    final Path pathArgument = arguments[0];
    if (includes != null) {
      for (Offset offset in includes) {
        if (!pathArgument.contains(offset))
          throw 'It called $methodName with a path that unexpectedly did not contain $offset.';
      }
    }
    if (excludes != null) {
      for (Offset offset in excludes) {
        if (pathArgument.contains(offset))
          throw 'It called $methodName with a path that unexpectedly contained $offset.';
      }
    }
    final Color actualColor = arguments[1];
    if (color != null && actualColor != color)
      throw 'It called $methodName with a color, $actualColor, which was not exactly the expected color ($color).';
    final double actualElevation = arguments[2];
    if (elevation != null && actualElevation != elevation)
      throw 'It called $methodName with an elevation, $actualElevation, which was not exactly the expected value ($elevation).';
    final bool actualTransparentOccluder = arguments[3];
    if (transparentOccluder != null && actualTransparentOccluder != transparentOccluder)
      throw 'It called $methodName with a transparentOccluder value, $actualTransparentOccluder, which was not exactly the expected value ($transparentOccluder).';
  }

  @override
  void match(Iterator<RecordedInvocation> call) {
    checkMethod(call, symbol);
    verifyArguments(call.current.invocation.positionalArguments);
    call.moveNext();
  }

  @protected
  void debugFillDescription(List<String> description) {
    if (includes != null && excludes != null) {
      description.add('that contains $includes and does not contain $excludes');
    } else if (includes != null) {
      description.add('that contains $includes');
    } else if (excludes != null) {
      description.add('that does not contain $excludes');
    }
    if (color != null)
      description.add('$color');
    if (elevation != null)
      description.add('elevation: $elevation');
    if (transparentOccluder != null)
      description.add('transparentOccluder: $transparentOccluder');
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    String result = methodName;
    if (description.isNotEmpty)
      result += ' with ${description.join(", ")}';
    return result;
  }
}

class _DrawImagePaintPredicate extends _DrawCommandPaintPredicate {
  _DrawImagePaintPredicate({ this.image, this.x, this.y, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawImage, 'an image', 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final ui.Image image;
  final double x;
  final double y;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final ui.Image imageArgument = arguments[0];
    if (image != null && imageArgument != image)
      throw 'It called $methodName with an image, $imageArgument, which was not exactly the expected image ($image).';
    final Offset pointArgument = arguments[0];
    if (x != null && y != null) {
      final Offset point = new Offset(x, y);
      if (point != pointArgument)
        throw 'It called $methodName with an offset coordinate, $pointArgument, which was not exactly the expected coordinate ($point).';
    } else {
      if (x != null && pointArgument.dx != x)
        throw 'It called $methodName with an offset coordinate, $pointArgument, whose x-coordinate not exactly the expected coordinate (${x.toStringAsFixed(1)}).';
      if (y != null && pointArgument.dy != y)
        throw 'It called $methodName with an offset coordinate, $pointArgument, whose y-coordinate not exactly the expected coordinate (${y.toStringAsFixed(1)}).';
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (image != null)
      description.add('image $image');
    if (x != null && y != null) {
      description.add('point ${new Offset(x, y)}');
    } else {
      if (x != null)
        description.add('x-coordinate ${x.toStringAsFixed(1)}');
      if (y != null)
        description.add('y-coordinate ${y.toStringAsFixed(1)}');
    }
  }
}

class _DrawImageRectPaintPredicate extends _DrawCommandPaintPredicate {
  _DrawImageRectPaintPredicate({ this.image, this.source, this.destination, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawImageRect, 'an image', 4, 3, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final ui.Image image;
  final Rect source;
  final Rect destination;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final ui.Image imageArgument = arguments[0];
    if (image != null && imageArgument != image)
      throw 'It called $methodName with an image, $imageArgument, which was not exactly the expected image ($image).';
    final Rect sourceArgument = arguments[1];
    if (source != null && sourceArgument != source)
      throw 'It called $methodName with a source rectangle, $sourceArgument, which was not exactly the expected rectangle ($source).';
    final Rect destinationArgument = arguments[2];
    if (destination != null && destinationArgument != destination)
      throw 'It called $methodName with a destination rectangle, $destinationArgument, which was not exactly the expected rectangle ($destination).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (image != null)
      description.add('image $image');
    if (source != null)
      description.add('source $source');
    if (destination != null)
      description.add('destination $destination');
  }
}

class _SomethingPaintPredicate extends _PaintPredicate {
  _SomethingPaintPredicate(this.predicate);

  final PaintPatternPredicate predicate;

  @override
  void match(Iterator<RecordedInvocation> call) {
    assert(predicate != null);
    RecordedInvocation currentCall;
    do {
      currentCall = call.current;
      if (currentCall == null)
        throw 'It did not call anything that was matched by the predicate passed to a "something" step of the paint pattern.';
      if (!currentCall.invocation.isMethod)
        throw 'It called $currentCall, which was not a method, when the paint pattern expected a method call';
      call.moveNext();
    } while (!_runPredicate(currentCall.invocation.memberName, currentCall.invocation.positionalArguments));
  }

  bool _runPredicate(Symbol methodName, List<dynamic> arguments) {
    try {
      return predicate(methodName, arguments);
    } on String catch (s) {
      throw 'It painted something that the predicate passed to a "something" step '
            'in the paint pattern considered incorrect:\n      $s\n  ';
    }
  }

  @override
  String toString() => 'a "something" step';
}

class _FunctionPaintPredicate extends _PaintPredicate {
  _FunctionPaintPredicate(this.symbol, this.arguments);

  final Symbol symbol;

  final List<dynamic> arguments;

  @override
  void match(Iterator<RecordedInvocation> call) {
    checkMethod(call, symbol);
    if (call.current.invocation.positionalArguments.length != arguments.length)
      throw 'It called ${_symbolName(symbol)} with ${call.current.invocation.positionalArguments.length} arguments; expected ${arguments.length}.';
    for (int index = 0; index < arguments.length; index += 1) {
      final dynamic actualArgument = call.current.invocation.positionalArguments[index];
      final dynamic desiredArgument = arguments[index];

      if (desiredArgument is Matcher) {
        expect(actualArgument, desiredArgument);
      } else if (desiredArgument != null && desiredArgument != actualArgument) {
        throw 'It called ${_symbolName(symbol)} with argument $index having value ${_valueName(actualArgument)} when ${_valueName(desiredArgument)} was expected.';
      }
    }
    call.moveNext();
  }

  @override
  String toString() {
    final List<String> adjectives = <String>[];
    for (int index = 0; index < arguments.length; index += 1)
      adjectives.add(arguments[index] != null ? _valueName(arguments[index]) : '...');
    return '${_symbolName(symbol)}(${adjectives.join(", ")})';
  }
}

class _SaveRestorePairPaintPredicate extends _PaintPredicate {
  @override
  void match(Iterator<RecordedInvocation> call) {
    checkMethod(call, #save);
    int depth = 1;
    while (depth > 0) {
      if (!call.moveNext())
        throw 'It did not have a matching restore() for the save() that was found where $this was expected.';
      if (call.current.invocation.isMethod) {
        if (call.current.invocation.memberName == #save)
          depth += 1;
        else if (call.current.invocation.memberName == #restore)
          depth -= 1;
      }
    }
    call.moveNext();
  }

  @override
  String toString() => 'a matching save/restore pair';
}

String _valueName(Object value) {
  if (value is double)
    return value.toStringAsFixed(1);
  return value.toString();
}

// Workaround for https://github.com/dart-lang/sdk/issues/28372
String _symbolName(Symbol symbol) {
  // WARNING: Assumes a fixed format for Symbol.toString which is *not*
  // guaranteed anywhere.
  final String s = '$symbol';
  return s.substring(8, s.length - 2);
}
