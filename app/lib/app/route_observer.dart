import 'package:flutter/widgets.dart';

/// Passed to [GoRouter] and used by screens that subscribe via [RouteAware].
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
