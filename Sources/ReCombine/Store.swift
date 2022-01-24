//
//  Store.swift
//  ReCombine
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

import Combine

/// Protocol that all action's must implement.
///
/// Example implementation:
/// ```
/// struct GetPostSuccess: Action {
///     let post: Post
/// }
/// ```
public protocol Action : CustomEquatable {}

public protocol CustomEquatable {
    func isEqualTo(_ other: CustomEquatable) -> Bool
}

extension CustomEquatable {
    public func isEqualTo(_ other: CustomEquatable) -> Bool {
        false
    }
}

extension CustomEquatable where Self: Equatable {
    public func isEqualTo(_ other: CustomEquatable) -> Bool {
        (other as? Self) == self
    }
}

/// A generic representation of a reducer function.
///
/// Reducer functions are pure functions which take a State and Action and return a State.
/// ```
/// let reducer: ReducerFn = { (state: State, action: Action) in
///     var state = state
///     switch action {
///         case let action as SetScores:
///             state.home = action.game.home
///             state.away = action.game.away
///             return state
///         default:
///             return state
///     }
/// }
/// ```
public typealias ReducerFn<S> = (inout S, Action) -> Void

/// A generic representation of a selector function.
///
/// Selector functions are pure functions which take a State and return data derived from that State.
/// ```
/// let selectPost = { (state: AppState) in
///     return state.singlePost.post
/// }
/// ```
public typealias SelectorFn<S, V> = (S) -> V

/// Combine-based state management.  Enables dispatching of actions, executing reducers, performing side-effects, and listening for the latest state.
///
/// Implements the `Publisher` protocol, allowing direct subscription for the latest state.
/// ```
/// import ReCombine
/// import Combine
///
/// struct CounterView {
///     struct Increment: Action {}
///     struct Decrement: Action {}
///
///     struct State {
///         var count = 0
///     }
///
///     static func reducer(state: State, action: Action) -> State {
///         var state = state
///         switch action {
///             case _ as Increment:
///                 state.count += 1
///                 return state
///             case _ as Decrement:
///                 state.count -= 1
///                 return state
///             default:
///                 return state
///         }
///     }
///
///     static let effect = Effect(dispatch: false)  { (actions: AnyPublisher<Action, Never>) in
///         actions.ofTypes(Increment.self, Decrement.self).print("Action Dispatched").eraseToAnyPublisher()
///     }
/// }
///
/// let store = Store(reducer: CounterView.reducer, initialState: CounterView.State(), effects: [CounterView.effect])
/// ```
open class Store<S>: Publisher {
    /// Publisher protocol - emits the state :nodoc:
    public typealias Output = S
    /// Publisher protocol :nodoc:
    public typealias Failure = Never

    private var state: S
    private var stateSubject: CurrentValueSubject<S, Never>
    private var actionSubject: PassthroughSubject<Action, Never>
    private var cancellableSet: Set<AnyCancellable> = []
    private let reducer: ReducerFn<S>

    /// Creates a new Store.
    /// - Parameter reducer: a single reducer function which will handle reducing state for all actions dispatched to the store.
    /// - Parameter initialState: the initial state.  This state will be used by consumers before the first action is dispatched.
    /// - Parameter epics: action based side-effects.  Each `Epic` element is processed for the lifetime of the `Store` instance.
    public init(reducer: @escaping ReducerFn<S>, initialState: S, epics: [Epic<S>] = []) {
        self.reducer = reducer
        state = initialState
        stateSubject = CurrentValueSubject(initialState)
        actionSubject = PassthroughSubject()

        for epic in epics {
            // Effects registered through init are maintained for the lifecycle of the Store.
            register(epic).store(in: &cancellableSet)
        }
    }

    /// Dispatch `Action` to the Store.  Calls reducer function with the passed `action` and previous state to generate a new state.
    /// - Parameter action: action to call the reducer with.
    ///
    /// Dispatching an action to the Store:
    /// ```
    /// struct Increment: Action {}
    ///
    /// store.dispatch(action: Increment())
    /// ```
    open func dispatch(action: Action) {
        reducer(&state, action)
        stateSubject.send(state)
        actionSubject.send(action)
    }

    /// Returns derived data from the application state based on a given selector function.
    ///
    /// Selector functions help return view-specific data from a minimum application state.
    ///
    /// **Example:** If a view needs the count of characters in a username, instead of storing both the username and the character count in state, store only the username, and use a selector to retrieve the count.
    /// ```
    /// store.select({ (state: AppState) in state.username.count })
    /// ```
    /// To enable reuse, abstract the closure into a separate property.
    /// ```
    /// let selectUsernameCount = { (state: AppState) in state.username.count }
    /// // ...
    /// store.select(selectUsernameCount)
    /// ```
    public func select<V: Equatable>(_ selector: @escaping (S) -> V) -> AnyPublisher<V, Never> {
        return map(selector).removeDuplicates().eraseToAnyPublisher()
    }

    /// Publisher protocol - use the internal stateSubject under the hood :nodoc:
    open func receive<T>(subscriber: T) where T: Subscriber, Failure == T.Failure, Output == T.Input {
        stateSubject.receive(subscriber: subscriber)
    }

    /// Registers an epic that processes from when this function is called until the returned `AnyCancellable` instance in cancelled.
    ///
    /// This can be useful for:
    /// 1. Epics that should not process for the entire lifetime of the `Store` instance.
    /// 2. Epics that need to capture a particular scope in it's `source` closure.
    ///
    /// ```
    /// - Parameter effect: action based side-effect.  It is processed until the returned `AnyCancellable` instance is cancelled.
    open func register(_ epic: Epic<S>) -> AnyCancellable {
        return epic.source(StatePublisher(storeSubject: stateSubject), actionSubject.eraseToAnyPublisher())
            .filter { _ in return epic.dispatch }
            .sink(receiveValue: { [weak self] action in self?.dispatch(action: action) })
    }
}


extension Store {

    func subStore<SubState>(
        toLocalState: @escaping  (S) -> SubState,
        epics: Epic<SubState>
    ) ->  Store<SubState> {
        // create a substore with the same initial state
        let subStore =  Store<SubState>(reducer: { localState, _ in
            // TODO: map actions
            localState = toLocalState(self.state)
        }, initialState: toLocalState(self.state), epics: [epics])

        // notify the substore of parent updates
        self
            .dropFirst()
            .sink(receiveValue: {  [weak subStore] in  subStore?.state = toLocalState($0) })
            .store(in: &self.cancellableSet)

        // return the new substore
        return subStore
    }

}


extension Store: ObservableObject {


}
