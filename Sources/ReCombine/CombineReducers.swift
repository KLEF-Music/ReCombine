//
//  CombineReducers.swift
//  ReCombine
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

import CasePaths

/// Combines multiple reducer functions into a single reducer function.  Each reducer function must reduce the same type.
/// - Parameter reducers: reducers to be combined into a single reducer.
///
/// Usually, you will want to to convert multiple key-specific reducers into a single reducer to represent an entire type using `forKey(_:use:)`.
/// ```
/// struct Scoreboard {
///     var home = 0
///     var away = 0
/// }
///
/// let scoreboardReducer: ReducerFn<Scoreboard> = combineReducers(
///    forKey(\.home, use: homeScoreReducer),
///    forKey(\.away, use: awayScoreReducer)
/// )
/// ```
public func combineReducers<S>(_ reducers: ReducerFn<S>...) -> ReducerFn<S> {
    return { (state, action) in
        reducers.forEach {
            $0(&state, action)
        }
    }
}

public func combineReducers<S>(array: [ReducerFn<S>]) -> ReducerFn<S> {
    return { (state, action) in
        array.forEach {
            $0(&state, action)
        }
    }
}

/// Convert a reducer function for a specific instance property into a reducer function for the entire instance.
/// - Parameter keyPath: The key of the instance property to be reduced.
/// - Parameter reducer: The reducer function for the given instance property.
///
/// Usually paired with `combineReducers(_:)`.
///
/// The following example converts a reducer that only reduces the home score into a reducer that reduces the entire Scoreboard:
/// ```
/// struct Scoreboard {
///     var home = 0
///     var away = 0
/// }
///
/// let homeScoreReducer: ReducerFn<Int> = { (state: Int, action) in
///     var state = state
///     switch action {
///         case let action as HomeScore:
///             state += 1
///             return state
///         default:
///             return state
///     }
/// }
///
/// let homeKeyReducer: ReducerFn<Scoreboard> = forKey(\.home, use: homeScoreReducer)
/// ```
public func forKey<S, K>(_ keyPath: WritableKeyPath<S, K>, use reducer: @escaping ReducerFn<K>) -> ReducerFn<S> {
    return { (state, action) in
        reducer(&state[keyPath: keyPath], action)
    }
}


public typealias TypedReducer<S, A> = (inout S, A) -> Void

public func typedReducer<S, SubAction>(_ reducer: @escaping TypedReducer<S, SubAction>) -> ReducerFn<S> {
    return { state, action in
        if let typeAction = action  as? SubAction {
            reducer(&state, typeAction)
        }
    }
}

public func typedReducer<S, ParentAction: Action, SubAction>(
    _ casePath: CasePath<ParentAction, SubAction>,
    _ reducer: @escaping TypedReducer<S, SubAction>
) -> ReducerFn<S> {
    return typedReducer { (state, action: ParentAction)  in
        if let typeAction = casePath.extract(from: action) {
            reducer(&state, typeAction)
        }
    }
}

