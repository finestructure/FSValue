//
//  Value.swift
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public typealias Key = String


public enum Value: Equatable {
    case bool(Bool)
    case int(Int)
    case string(String)
    case double(Double)
    case dictionary([Key: Value])
    case array([Value])
    case null
}


extension Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([Key: Value].self) {
            self = .dictionary(value)
            return
        }

        if let value = try? container.decode([Value].self) {
            self = .array(value)
            return
        }

        if let string = try? container.decode(String.self),
            // when decoding YML, strings with a colon get
            // parsed as Numeric (with value 0) *)
            // therefore just accept them as string and return
            // *) probably due to dictionary syntax
            string.contains(":") {
            self = .string(string)
            return
        }

        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        if container.decodeNil() {
            self = .null
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "could not find any decodable value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let v):
            try container.encode(v)
        case .bool(let v):
            try container.encode(v)
        case .int(let v):
            try container.encode(v)
        case .double(let v):
            try container.encode(v)
        case .dictionary(let v):
            try container.encode(v)
        case .array(let v):
            try container.encode(v)
        case .null:
            try container.encodeNil()
        }
    }
}


extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bool(let v):
            return v ? "true" : "false"
        case .int(let v):
            return v.description
        case .string(let v):
            return "\"\(v)\""
        case .double(let v):
            return v.description
        case .dictionary(let v):
            return v.description
        case .array(let v):
            return v.description
        case .null:
            return "null"
        }
    }
}


extension Value {
    public var string: String {
        switch self {
        case .bool(let v):
            return v.description
        case .int(let v):
            return v.description
        case .string(let v):
            return v
        case .double(let v):
            return v.description
        case .dictionary(let v):
            return v.description
        case .array(let v):
            return v.description
        case .null:
            return "null"
        }
    }
}


extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}


extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}


extension Value: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        let dict = Dictionary(uniqueKeysWithValues: elements)
        self = .dictionary(dict)
    }
}


extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}


extension Value {
    subscript(key: String) -> Value? {
        let keyPaths = key.split(separator: ".")
        guard let firstSubstring = keyPaths.first else { return nil }
        let firstKeyPath = String(firstSubstring)
        let remainder = keyPaths.dropFirst().joined(separator: ".")

        let nested: Value?

        switch (self, Int(firstKeyPath)) {
        case let (.dictionary(d), nil):
            nested = d[firstKeyPath]
        case let (.array, .some(index)):
            nested = self[index]
        default:
            return nil
        }

        return remainder.isEmpty ? nested : nested?[remainder]
    }

    subscript(index: Int) -> Value? {
        switch self {
        case .array(let v):
            return index >= 0
                ? v[index]
                : v[v.index(v.endIndex, offsetBy: index)]  // from end
        default:
            return nil
        }
    }
}
