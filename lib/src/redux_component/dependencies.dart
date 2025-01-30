import '../redux/redux.dart';
import 'basic.dart';

class Dependencies<T> {
  final Map<String, Dependent<T>> slots;
  final Dependent<T> adapter;

  /// Use [adapter: NoneConn<T>() + Adapter<T>()] instead of [adapter: Adapter<T>()],
  /// Which is better reusability and consistency.
  Dependencies({
    this.slots,
    this.adapter,
  }) : assert(adapter.isAdapter(),
            'The dependent must contains adapter.');

  Reducer<T> createReducer() {
    final List<SubReducer<T>> subs = <SubReducer<T>>[];
    if (slots.isNotEmpty) {
      subs.addAll(slots.entries.map<SubReducer<T>>(
        (MapEntry<String, Dependent<T>> entry) =>
            entry.value.createSubReducer(),
      ));
    }

    subs.add(adapter.createSubReducer());
  
    return combineReducers(<Reducer<T>>[combineSubReducers(subs)]);
  }

  Dependent<T> slot(String type) => slots[type];

  Dependencies<T> trim() =>
      adapter != null || slots.isNotEmpty == true ? this : null;
}
