//
//  File.swift
//  
//
//  Created by RORY KELLY on 24/01/2022.
//

import Foundation
import CasePaths

public extension V2 {


    static func combineReducers<S, A>(_ array: ReducerFn<S, A>...) -> ReducerFn<S, A> {
        return { (state, action) in
            array.forEach {
                $0(&state, action)
            }
        }
    }


    static func combineReducers<S, A>(array: [ReducerFn<S, A>]) -> ReducerFn<S, A> {
        return { (state, action) in
            array.forEach {
                $0(&state, action)
            }
        }
    }
    
    static func forKey<ParentState, ParentAction, SubAction>(
        _ keyPath: WritableKeyPath<ParentState, SubAction>,
        _ casePath: CasePath<ParentAction, SubAction>
    ) -> ReducerFn<ParentState, ParentAction> {
        return { (parentState, parentAction) in
            if let subAction = casePath.extract(from: parentAction) {
                parentState[keyPath: keyPath] = subAction
            }
        }
    }
    
    static func forKey<ParentState, ParentKey, ParentAction, SubAction>(
        _ keyPath: WritableKeyPath<ParentState, ParentKey>,
        _ casePath: CasePath<ParentAction, SubAction>,
        use reducer: @escaping ReducerFn<ParentKey, SubAction>) -> ReducerFn<ParentState, ParentAction> {
            return { (parentState, parentAction) in
                if let subAction = casePath.extract(from: parentAction) {
                    reducer(&parentState[keyPath: keyPath], subAction)
                }
            }
        }
}

