import 'dart:ui';

/// A canvas that only records which drawing calls were made.
class CountingCanvas implements Canvas {
  final Map<Symbol, int> counts = <Symbol, int>{};
  final List<String> log = <String>[];
  int saveCount = 1;

  int count(Symbol call) => counts[call] ?? 0;

  /// Every call whose name starts with `draw`.
  int get draws => counts.entries
      .where((e) => e.key.toString().startsWith('Symbol("draw'))
      .fold(0, (sum, e) => sum + e.value);

  @override
  void save() {
    saveCount++;
    _record(#save, const <Object?>[]);
  }

  @override
  void restore() {
    saveCount--;
    _record(#restore, const <Object?>[]);
  }

  @override
  int getSaveCount() => saveCount;

  void _record(Symbol name, List<Object?> args) {
    counts[name] = (counts[name] ?? 0) + 1;
    log.add('$name${args.map(_describe).join(',')}');
  }

  static String _describe(Object? arg) {
    if (arg is double) return arg.toStringAsFixed(3);
    if (arg is Offset) {
      return '(${arg.dx.toStringAsFixed(2)},${arg.dy.toStringAsFixed(2)})';
    }
    if (arg is Paint) return 'paint(${arg.color.toARGB32().toRadixString(16)})';
    return arg.runtimeType.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    _record(invocation.memberName, invocation.positionalArguments);
    return null;
  }
}
