import 'package:flutter/widgets.dart' hide Action, Page;

import '../redux/basic.dart';
import 'basic.dart';
import 'context.dart';
import 'dependencies.dart';
import 'helper.dart';
import 'lifecycle.dart';
import 'logic.dart';

/// Wrapper ComponentWidget if needed like KeepAlive, RepaintBoundary etc.
typedef WidgetWrapper = Widget Function(Widget child);

@immutable
abstract class Component<T> extends Logic<T> implements AbstractComponent<T> {
  final ViewBuilder<T> _view;
  final ShouldUpdate<T> _shouldUpdate;
  final WidgetWrapper _wrapper;
  final bool _clearOnDependenciesChanged;

  ViewBuilder<T> get protectedView => _view;
  ShouldUpdate<T> get protectedShouldUpdate => _shouldUpdate;
  WidgetWrapper get protectedWrapper => _wrapper;
  bool get protectedClearOnDependenciesChanged => _clearOnDependenciesChanged;

  Component({
    @required ViewBuilder<T> view,
    Reducer<T> reducer,
    ReducerFilter<T> filter,
    Effect<T> effect,
    Dependencies<T> dependencies,
    ShouldUpdate<T> shouldUpdate,
    WidgetWrapper wrapper,

    /// implement [StateKey] in T instead of using key in Logic.
    /// class T implements StateKey {
    ///   Object _key = UniqueKey();
    ///   Object key() => _key;
    /// }
    @deprecated Key Function(T) key,
    bool clearOnDependenciesChanged = false,
  })  : _view = view,
        _wrapper = wrapper ?? _wrapperByDefault,
        _shouldUpdate = shouldUpdate ?? updateByDefault<T>(),
        _clearOnDependenciesChanged = clearOnDependenciesChanged,
        super(
          reducer: reducer,
          filter: filter,
          effect: effect,
          dependencies: dependencies,
          // ignore:deprecated_member_use_from_same_package
          key: key,
        );

  @override
  Widget buildComponent(
    Store<Object> store,
    Get<Object> getter, {
    @required DispatchBus bus,
    @required Enhancer<Object> enhancer,
  }) {
    /// Check bus: DispatchBusDefault(); enhancer: EnhancerDefault<Object>();

    return protectedWrapper(
      ComponentWidget<T>(
        component: this,
        getter: asGetter<T>(getter),
        store: store,
        key: key(getter()),
        bus: bus,
        enhancer: enhancer,
      ),
    );
  }

  @override
  ComponentContext<T> createContext(
    Store<Object> store,
    BuildContext buildContext,
    Get<T> getState, {
    @required void Function() markNeedsBuild,
    @required DispatchBus bus,
    @required Enhancer<Object> enhancer,
  }) {
    return ComponentContext<T>(
      logic: this,
      store: store,
      buildContext: buildContext,
      getState: getState,
      view: enhancer.viewEnhance(protectedView, this, store),
      shouldUpdate: protectedShouldUpdate,
      name: name,
      markNeedsBuild: markNeedsBuild,
      sidecarCtx: adapterDep().createContext(
        store,
        buildContext,
        getState,
        bus: bus,
        enhancer: enhancer,
      ),
      enhancer: enhancer,
      bus: bus,
    );
  }

  ComponentState<T> createState() => ComponentState<T>();

  String get name => cache<String>('name', () => runtimeType.toString());

  static ShouldUpdate<K> neverUpdate<K>() => (K _, K __) => false;

  static ShouldUpdate<K> alwaysUpdate<K>() => (K _, K __) => true;

  static ShouldUpdate<K> updateByDefault<K>() =>
      (K _, K __) => !identical(_, __);

  static Widget _wrapperByDefault(Widget child) => child;
}

class ComponentWidget<T> extends StatefulWidget {
  final Component<T> component;
  final Store<Object> store;
  final Get<T> getter;
  final DispatchBus bus;
  final Enhancer<Object> enhancer;

  const ComponentWidget({
    @required this.component,
    @required this.store,
    @required this.getter,
    this.bus,
    this.enhancer,
    Key key,
  })  : super(key: key);

  @override
  ComponentState<T> createState() => component.createState();
}

class ComponentState<T> extends State<ComponentWidget<T>> {
  ComponentContext<T> _ctx;

  ComponentContext<T> get ctx => _ctx;

  @mustCallSuper
  @override
  Widget build(BuildContext context) => _ctx.buildWidget();

  @override
  @protected
  @mustCallSuper
  void reassemble() {
    super.reassemble();
    _ctx.clearCache();
    _ctx.onLifecycle(LifecycleCreator.reassemble());
  }

  @mustCallSuper
  @override
  void initState() {
    super.initState();

    /// init context
    _ctx = widget.component.createContext(
      widget.store,
      context,
      () => widget.getter(),
      markNeedsBuild: () {
        if (mounted) {
          setState(() {});
        }
      },
      bus: widget.bus,
      enhancer: widget.enhancer,
    );

    /// register store.subscribe
    _ctx.registerOnDisposed(widget.store.subscribe(() => _ctx.onNotify()));

    _ctx.onLifecycle(LifecycleCreator.initState());
  }

  @mustCallSuper
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.component.protectedClearOnDependenciesChanged != false) {
      _ctx.clearCache();
    }

    _ctx.onLifecycle(LifecycleCreator.didChangeDependencies());
  }

  @mustCallSuper
  @override
  void deactivate() {
    super.deactivate();
    _ctx.onLifecycle(LifecycleCreator.deactivate());
  }

  @mustCallSuper
  @override
  void didUpdateWidget(ComponentWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ctx.didUpdateWidget();
    _ctx.onLifecycle(LifecycleCreator.didUpdateWidget());
  }

  @mustCallSuper
  void disposeCtx() {
    if (!_ctx.isDisposed) {
      _ctx
        ..onLifecycle(LifecycleCreator.dispose())
        ..dispose();
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    disposeCtx();
    super.dispose();
  }
}
