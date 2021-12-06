//
//  File.swift
//  
//
//  Created by RORY KELLY on 05/12/2021.
//

import Foundation
import Combine
import CasePaths

public typealias EffectFn<S, A> = (AnyPublisher<A, Never>) -> AnyPublisher<Action, Never>

extension Epic {

    public init(dispatch: Bool = true, _ source: @escaping EffectFn<S, Action>) {
        self.dispatch = dispatch
        self.source = { _, actions in source(actions) }
    }
    
}

public func effect<S>(dispatch: Bool = true, _ closure: @escaping EffectFn<S, Action>)  -> Epic<S> {
    Epic (dispatch: dispatch) { actions in
        closure(actions.eraseToAnyPublisher())
    }
}

public func emptyEffect<S>()  -> Epic<S> {
    Epic (dispatch: false) { actions in actions.ignoreAndErase() }
}
