//
//  File.swift
//  
//
//  Created by RORY KELLY on 24/01/2022.
//

import Foundation
import Combine
import CasePaths

public extension V2 {

    typealias EpicFn<S, A> = (StatePublisher<S>, AnyPublisher<A, Never>) -> AnyPublisher<A, Never>

    /// Configures an Epic from a source function and a dispatch option.
    ///
    /// Epic are used for side-effects in ReCombine applications, but allow acess to the current state of the store. See https://redux-observable.js.org/docs/basics/Epics.html for a js implementation
    struct Epic<S, A> {
        /// When true, the emitted actions from the `source` Action Publisher will be dispatched to the store.  If false, the emitted actions will be ignored.
        public let dispatch: Bool
        /// A closure with takes in a State Publisher , an Action Publisher and returns an Action Publisher
        public let source: EpicFn<S, A>

        public init(dispatch: Bool = true, _ source: @escaping EpicFn<S, A>) {
            self.dispatch = dispatch
            self.source = source
        }
    }


    static func emptyEpic<S, A>() -> Epic<S,A> {
        Epic{ _, _ in Empty().eraseToAnyPublisher() }
    }

    static func createEpic<S, A>(dispatch: Bool = true, _ source: @escaping EpicFn<S, A>)-> Epic<S, A> {
        Epic(dispatch: dispatch, source)
    }

    static func combineEpics<S, A>(dispatch: Bool = true, epicsArray: [Epic<S, A>]) -> Epic<S, A> {
        Epic(dispatch: dispatch) { state, actions in
            let action = epicsArray.map { effect in effect.source(state, actions).filter { _ in effect.dispatch } }
            return Publishers.MergeMany(action).eraseToAnyPublisher()
        }
    }

    static func combineEpics<S, A>(dispatch: Bool = true, _ epics: Epic<S, A>...) -> Epic<S, A> {
        combineEpics(dispatch: dispatch, epicsArray: epics)
    }

}
