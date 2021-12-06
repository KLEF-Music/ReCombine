//
//  Epic.swift
//  
//
//  Created by RORY KELLY on 15/09/2021.
//

import Foundation
import Combine
import CasePaths


public typealias EpicFn<S, A> = (StatePublisher<S>, AnyPublisher<A, Never>) -> AnyPublisher<Action, Never>

/// Configures an Epic from a source function and a dispatch option.
///
/// Epic are used for side-effects in ReCombine applications, but allow acess to the current state of the store. See https://redux-observable.js.org/docs/basics/Epics.html for a js implementation
public struct Epic<S> {
    /// When true, the emitted actions from the `source` Action Publisher will be dispatched to the store.  If false, the emitted actions will be ignored.
    public let dispatch: Bool
    /// A closure with takes in a State Publisher , an Action Publisher and returns an Action Publisher
    public let source: EpicFn<S, Action>

    public init(dispatch: Bool = true, _ source: @escaping EpicFn<S, Action>) {
        self.dispatch = dispatch
        self.source = source
    }
}

public struct StatePublisher<S> {
    public let changes: AnyPublisher<S, Never>
    public let state: () -> S

    public init(
        changes: AnyPublisher<S, Never>,
        state: @escaping () -> S) {
            self.changes = changes
            self.state = state
        }

}

public extension StatePublisher  {

    init(storeSubject: CurrentValueSubject<S, Never>) {
        self.changes = storeSubject.eraseToAnyPublisher()
        self.state = { return storeSubject.value }
    }

#if swift(>=5.2)
    func callAsFunction() -> S {
        return state()
    }
#endif
    
}

extension Epic {

    public func mapState<ParentState>(toLocalState: KeyPath<ParentState, S>) -> Epic<ParentState> {
        forKey(toLocalState: toLocalState, use: self)
    }

    public func mapState<ParentState>(toLocalState: @escaping (ParentState) -> S) -> Epic<ParentState> {
        forKey(toLocalState: toLocalState, use: self)
    }

}

public func forKey<SubState, ParentState>(
    toLocalState: KeyPath<ParentState, SubState>,
    use: Epic<SubState>
) -> Epic<ParentState>{
    Epic<ParentState>(dispatch: use.dispatch)  { state, actions in
        let subState = state.changes.map{ $0[keyPath: toLocalState] }.eraseToAnyPublisher()
        let subStatePublisher = StatePublisher(changes: subState, state: { state()[keyPath: toLocalState] })
        return use.source(subStatePublisher, actions)
    }
}

public func forKey<SubState, ParentState>(
    toLocalState: @escaping (ParentState) -> SubState,
    use: Epic<SubState>
) -> Epic<ParentState>{
    Epic<ParentState>(dispatch: use.dispatch)  { state, actions in
        let subState = state.changes.map{ toLocalState($0) }.eraseToAnyPublisher()
        let subStatePublisher = StatePublisher(changes: subState, state: { toLocalState(state()) })
        return use.source(subStatePublisher, actions)
    }
}


public func epic<S>(dispatch: Bool = true, _ closure: @escaping EpicFn<S, Action>)  -> Epic<S> {
    Epic (dispatch: dispatch) { state, actions in
        closure(state, actions)
    }
}

public func combineEpics<S>(dispatch: Bool = true, epicsArray: [Epic<S>]) -> Epic<S> {
    Epic<S>(dispatch: dispatch) { state, actions in
        let action = epicsArray.map { effect in effect.source(state, actions).filter { _ in effect.dispatch } }
        return Publishers.MergeMany(action).eraseToAnyPublisher()
    }
}

public func combineEpics<S>(dispatch: Bool = true, _ epics: Epic<S>...) -> Epic<S> {
    combineEpics(dispatch: dispatch, epicsArray: epics)
}
