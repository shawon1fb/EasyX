//
//  ServiceKey.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//

import Foundation

struct ServiceKey: Hashable {
    let type: ObjectIdentifier
    let name: String?
    let scope: String?
}
extension ServiceKey: Equatable {
    static func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
        return lhs.type == rhs.type && lhs.name == rhs.name && lhs.scope == rhs.scope
    }
}
