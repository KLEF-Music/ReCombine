//
//  Epic.swift
//  
//
//  Created by RORY KELLY on 15/09/2021.
//

import Foundation
import Combine

/// Configures an Epic from a source function and a dispatch option.
///
/// Epic are used for side-effects in ReCombine applications, but allow acess to the current state of the store. See https://redux-observable.js.org/docs/basics/Epics.html for a js implementation
public struct Epic<S> {
    /// When true, the emitted actions from the `source` Action Publisher will be dispatched to the store.  If false, the emitted actions will be ignored.
    public let dispatch: Bool
    /// A closure with takes in a State Publisher , an Action Publisher and returns an Action Publisher
    public let source: (StatePublisher<S>, AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>

    public init(dispatch: Bool, _ source: @escaping (StatePublisher<S>, AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>) {
        self.dispatch = dispatch
        self.source = source
    }
}

public struct StatePublisher<S> {
    let changes: AnyPublisher<S, Never>
    let state: () -> S
}

public extension StatePublisher{

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
