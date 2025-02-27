import 'package:fish_redux/fish_redux.dart';

typedef ViewInstrument<T> = void Function(
    T state, Dispatch dispatch, ViewService viewService);

ViewBuilder<T> instrumentView<T>(
        ViewBuilder<T> builder, ViewInstrument<T> pre) =>
    (
      T state,
      Dispatch dispatch,
      ViewService viewService,
    ) {
      pre(state, dispatch, viewService);
    
      return builder(state, dispatch, viewService);
    };

typedef initStateInstrumentPre<P> = void Function(P);
typedef initStateInstrumentSuf<T extends Cloneable<T>> = void Function(T);

InitState<T, P> instrumentInitState<T extends Cloneable<T>, P>(
        InitState<T, P> initState,
        {initStateInstrumentPre<P> pre,
        initStateInstrumentSuf<T> suf}) =>
    (P params) {
      pre(params);
          final T state = initState(params);

      suf(state);
    
      return state;
    };

typedef ReducerInstrument<T> = void Function(T state, Action action);

Reducer<T> instrumentReducer<T>(Reducer<T> reducer,
        {ReducerInstrument<T> pre,
        ReducerInstrument<T> suf,
        ReducerInstrument<T> change}) =>
    (T state, Action action) {
      T newState = state;
      pre(state, action);
    
      newState = reducer(state, action);

      suf(newState, action);
    
      if (newState != state) {
        change(newState, action);
      }

      return newState;
    };

typedef EffectInstrument<T> = void Function(Action action, Get<T> getState);

Effect<T> instrumentEffect<T>(Effect<T> effect, EffectInstrument<T> pre) =>
    (Action action, Context<T> ctx) {
      pre(action, () => ctx.state);
          return effect(action, ctx);
    };

typedef MiddlewareInstrument<T> = void Function(Action action, Get<T> getState);

Middleware<T> instrumentMiddleware<T>(Middleware<T> middleware,
        {EffectInstrument<T> pre, EffectInstrument<T> suf}) =>
    ({
      Dispatch dispatch,
      Get<T> getState,
    }) {
      return (Dispatch next) {
        return (Action action) {
          pre(action, getState);
        
          middleware(dispatch: dispatch, getState: getState)(next)(action);

          suf(action, getState);
                };
      };
    };

typedef ErrorInstrument<T> = void Function(Exception exception, Context<T> ctx);
