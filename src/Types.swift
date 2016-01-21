// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/**
 * A config map is a mapping of string values and config values. This is the
 * primary mechanism used for merging overlays.
 */
public typealias ConfigMap = [String:Value]

/**
 * Merges a set of config maps in reverse order of precedence.
 */
public func mergeConfigs(configs: [ConfigMap]) -> ConfigMap {
    return configs.reduce(ConfigMap()) { m1, m2 in
        var copy = m1
        for (key, value) in m2 {
            switch value {
            case .StringLiteral: copy[key] = value
            case .IntegerLiteral: copy[key] = value
            case .FloatLiteral: copy[key] = value
            case .BoolLiteral: copy[key] = value
                
            case let .ArrayLiteral(items):
                var newItems = copy[key]?.array ?? []
                for item in items {
                    newItems.append(item)
                }
                copy[key] = Value.ArrayLiteral(newItems)
                
            case let .DictionaryLiteral(items):
                let newItems = mergeConfigs([copy[key]?.dictionary ?? [:], items])
                copy[key] = Value.DictionaryLiteral(newItems)
            }
            
        }
        
        return copy
    }
}

/**
 * Represents the top-level declaration defined within the package file.
 */
final public class DeclarationType {
    /** The name of the defined type. */
    public var name: String = ""
    
    /** The properties associated with the declaration. */
    public var properties: ConfigMap = [:]
}

/**
 * Defines all of the available data types that can be stored within a
 * `DeclarationType`.
 */
public enum Value {
    case StringLiteral(String)
    case IntegerLiteral(Int)
    case FloatLiteral(Double)
    case BoolLiteral(Bool)
    
    case DictionaryLiteral(ConfigMap)
    case ArrayLiteral([Value])
}   

/**
 * A set of extensions to provide proper names for each of the enums.
 */
extension Value {
    public static let StringType = "Value.StringLiteral"
    public static let IntegerType = "Value.IntegerLiteral"
    public static let FloatType = "Value.FloatLiteral"
    public static let BoolType = "Value.BoolLiteral"
    public static let DictionaryType = "Value.DictionaryLiteral"
    public static let ArrayType = "Value.ArrayLiteral"

    public var typeName: String {
        switch self {
        case .StringLiteral: return Value.StringType
        case .IntegerLiteral: return Value.IntegerType
        case .FloatLiteral: return Value.FloatType
        case .BoolLiteral: return Value.BoolType
        case .DictionaryLiteral: return Value.DictionaryType
        case .ArrayLiteral: return Value.ArrayType
        }
    }
}

/**
 * A set of extensions to make working with associated enums easier.
 */
extension Value {
    public var string: String? {
        if case let .StringLiteral(value) = self { return value }
        return nil
    }
    
    public var integer: Int? {
        if case let .IntegerLiteral(value) = self { return value }
        return nil
    }

    public var float: Double? {
        if case let .FloatLiteral(value) = self { return value }
        return nil
    }

    public var bool: Bool? {
        if case let .BoolLiteral(value) = self { return value }
        return nil
    }
    
    public var dictionary: [String:Value]? {
        if case let .DictionaryLiteral(value) = self { return value }
        return nil
    }
    
    public var array: [Value]? {
        if case let .ArrayLiteral(value) = self { return value }
        return nil
    }
}
