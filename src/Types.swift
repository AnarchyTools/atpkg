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
    
    case Map([String:Value])
    case Vector([Value])
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
    
    public var map: [String:Value]? {
        if case let .Map(value) = self { return value }
        return nil
    }
    
    public var vector: [Value]? {
        if case let .Vector(value) = self { return value }
        return nil
    }
}
