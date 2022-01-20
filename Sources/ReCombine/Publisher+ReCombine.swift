//
//  Publisher+ReCombine.swift
//  ReCombine
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

import Combine
import Foundation
import CasePaths

extension Publisher where Self.Output : Action {
    /// Wraps this publisher with a type eraser to return a generic `Action` protocol.
    ///
    /// Use to expose a generic `Action`, rather than this publisher’s actual Action implementer.
    /// This will help satisfy constraints for Publishers that are expected to be of type `Action`.
    /// ```
    /// // Below: Error: Cannot convert value of type 'AnyPublisher<GetPost, Never>' to specified type 'AnyPublisher<Action, Never>'
    /// let actionPublisher: AnyPublisher<Action, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .handleEvents(receiveOutput: { _ in print("Got it") })
    ///     .eraseToAnyPublisher()
    /// // Below: No error with eraseActionType()
    /// let actionPublisher: AnyPublisher<Action, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .handleEvents(receiveOutput: { _ in print("Got it") })
    ///     .eraseActionType()
    ///     .eraseToAnyPublisher()
    /// ```
    public func eraseActionType() -> Publishers.Map<Self, Action> {
        return map({ action in action as Action })
    }
    
}


extension Publisher where Failure == Never  {

    public func ignoreAndErase() -> AnyPublisher<Action, Never> {
        ignoreOutput()
            .compactMap{ $0 as? Action }
            .eraseToAnyPublisher()
    }

    public func on<A>(_ type: A.Type, _  run: @escaping (A) -> Void) -> AnyPublisher<Action, Never> {
        ofType(A.self)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {
                run($0)
            }).ignoreAndErase()
    }

    public func on<ParentAction, SubAction>(_ casePath: CasePath<ParentAction, SubAction>, _  run: @escaping (SubAction) -> Void) -> AnyPublisher<Action, Never> {
        ofType(casePath)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {
                run($0)
            }).ignoreAndErase()
    }

    /// Filter that includes only the `Action` type that is given, and maps to that specific Action type.
    ///
    /// The code block converts the action stream from `AnyPublisher<Action, Never>` to `AnyPublisher<GetPost, Never>`:
    /// ```
    /// let getPostOnly: AnyPublisher<GetPost, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .eraseToAnyPublisher()
    /// ```
    public func ofType<A>(_: A.Type) -> Publishers.CompactMap<Self, A> {
        return compactMap({ action in action as? A })
    }


    public func ofType<Parent, SubAction>(_ casePath: CasePath<Parent, SubAction>) -> AnyPublisher<SubAction, Failure> {
        return ofType(Parent.self).compactMap(casePath.extract).eraseToAnyPublisher()
    }


}

extension Publisher where Self.Output: Action, Failure == Never {

    public func erase() -> AnyPublisher<Action, Never> {
        eraseActionType().eraseToAnyPublisher()
    }

}

public func merge<Upstream>(_ upstream: Upstream...) -> AnyPublisher<Upstream.Output, Upstream.Failure> where Upstream : Publisher {
    return Publishers.MergeMany<Upstream>(upstream).eraseToAnyPublisher()
}


