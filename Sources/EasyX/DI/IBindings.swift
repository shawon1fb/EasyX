//
//  IBindings.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//

import Foundation

public protocol IBindings {
    associatedtype T
    func getDependency() -> T
}
