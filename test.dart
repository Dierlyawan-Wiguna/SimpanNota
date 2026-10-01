import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void inc() {
    state++;
    ref.read(provider);
  }
}

final provider = NotifierProvider.autoDispose<MyNotifier, int>(MyNotifier.new);
