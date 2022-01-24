//
//  Combine+DSL.swift
//  
//
//  Created by Dmitry Zhurov on 17.01.2022.
//

import Foundation

@resultBuilder
public struct ReducersBuilder {
    public static func buildBlock<S>(_ partialResults: ReducerFn<S>...) -> ReducerFn<S> {
        combineReducers(array: partialResults)
    }
}

@resultBuilder
public struct EpicBuilder {
    public static func buildBlock<S>(_ components: Epic<S>...) -> Epic<S> {
        combineEpics(dispatch: true, epicsArray: components)
    }
}


