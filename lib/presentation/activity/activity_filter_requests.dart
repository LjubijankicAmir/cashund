import 'dart:async';

import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:injectable/injectable.dart';

/// Asks Activity to show a filtered list, from anywhere in the app, e.g.
/// "See 11 transactions in Activity" in Insights. The shell switches to the
/// Activity tab; Activity applies the filter, even if it isn't built yet.
@lazySingleton
class ActivityFilterRequests {
  final _requests = StreamController<TransactionFilter>.broadcast();
  TransactionFilter? _pending;

  /// Each new request, as it comes.
  Stream<TransactionFilter> get requests => _requests.stream;

  void open(TransactionFilter filter) {
    _pending = filter;
    _requests.add(filter);
  }

  /// The latest request not handled yet, if any; handles it.
  TransactionFilter? take() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  @disposeMethod
  Future<void> dispose() => _requests.close();
}
