import 'package:flutter_riverpod/flutter_riverpod.dart';

final typingProvider =
    StateProvider.family<bool, String>((ref, threadId) => false);
