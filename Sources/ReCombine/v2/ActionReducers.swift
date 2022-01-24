//
//  ActionReducerFn.swift
//  
//
//  Created by RORY KELLY on 24/01/2022.
//

import Foundation

public extension V2 {
    public typealias ReducerFn<S, ActionType> = (inout S, ActionType) -> Void
}



