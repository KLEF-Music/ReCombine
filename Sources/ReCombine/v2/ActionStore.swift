//
//  ActionStore.swift
//  
//
//  Created by RORY KELLY on 24/01/2022.
//

import Combine
import Foundation
import CasePaths

public enum V2 {
    open class Store<StateType, ActionType> : Publisher {
        /// Publisher protocol - emits the state :nodoc:
        public typealias Output = StateType
        /// Publisher protocol :nodoc:
        public typealias Failure = Never

        public var state: StateType {
            get {
                stateSubject.value
            }
        }
        private var stateSubject: CurrentValueSubject<StateType, Never>
        private var actionSubject: PassthroughSubject<ActionType, Never>
        private var cancellableSet: Set<AnyCancellable> = []
        private let reducer: ReducerFn<StateType, ActionType>

        public init(
            reducer: @escaping ReducerFn<StateType, ActionType>,
            initialState: StateType,
            epics: Epic<StateType, ActionType> = emptyEpic()
        ) {
            self.reducer = reducer
            stateSubject = CurrentValueSubject(initialState)
            actionSubject = PassthroughSubject()

            // Effects registered through init are maintained for the lifecycle of the Store.
            register(epics).store(in: &cancellableSet)
        }

        open func dispatch(action: ActionType) {
            reducer(&stateSubject.value, action)
            //stateSubject.send(state)
            actionSubject.send(action)
        }

        public func select<V: Equatable>(_ selector: @escaping (StateType) -> V) -> AnyPublisher<V, Never> {
            return map(selector).removeDuplicates().eraseToAnyPublisher()
        }

        open func receive<T>(subscriber: T) where T: Subscriber, Failure == T.Failure, Output == T.Input {
            stateSubject.receive(subscriber: subscriber)
        }

        open func register(_ epic: Epic<StateType, ActionType>) -> AnyCancellable {
            return epic.source(StatePublisher(storeSubject: stateSubject), actionSubject.eraseToAnyPublisher())
                .filter { _ in return epic.dispatch }
                .sink(receiveValue: { [weak self] action in self?.dispatch(action: action) })
        }
    }


}


extension V2.Store {

    public func subStore<SubState, SubAction>(
        toLocalState: @escaping  (StateType) -> SubState,
        fromLocalAction: @escaping  (SubAction) -> ActionType,
        epics: V2.Epic<SubState, SubAction> = V2.emptyEpic()
    ) ->  V2.Store<SubState, SubAction> {
        // create a substore with the same initial state
        let subStore = V2.Store<SubState, SubAction>(
            reducer: { localState, localAction in
                // Send the sub actions to the parent
                self.dispatch(action: fromLocalAction(localAction))
                // Update the local state with the parent state
                // which has already been reduced.
                localState = toLocalState(self.state)

            },
            initialState: toLocalState(self.state),
            epics: epics
        )

        // notify the substore of parent updates
        self
            .dropFirst()
            .sink(receiveValue: {  [weak subStore] in  subStore?.stateSubject.value = toLocalState($0) })
            .store(in: &self.cancellableSet)

        // return the new substore
        return subStore
    }

    public func subStore<SubState, SubAction>(
        toLocalState: @escaping  (StateType) -> SubState,
        fromLocalAction: CasePath<ActionType, SubAction>,
        epics: V2.Epic<SubState, SubAction> = V2.emptyEpic()
    ) ->  V2.Store<SubState, SubAction> {
        return self.subStore(
            toLocalState: toLocalState,
            fromLocalAction: fromLocalAction.embed,
            epics: epics
        )
    }


}

