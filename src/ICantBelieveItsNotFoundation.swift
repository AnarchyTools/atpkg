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

import Foundation

//SR-138
extension String {
    var toNSString: NSString {
        #if os(Linux)
        return self.bridge()
        #elseif os(OSX)
        return (self as NSString)
        #endif
    }
    #if os(Linux)
    public func substring(with range: Range<String.Index>) -> String {
        var result = ""
        result.reserveCapacity(range.count)
        for idx in range {
            result.append(self.characters[idx])
        }
        return result
    }

    public func substring(to index: Int) -> String {
        return self.substring(with: self.startIndex..<self.startIndex.advanced(by:index))
    }
    #endif
}
extension NSString {
    var toString: String {
        #if os(Linux)
        return self.bridge()
        #elseif os(OSX)
        return (self as String)
        #endif
    }
}

// These parts of the "great swift renaming" are not yet implemented on Linux
#if os(Linux)
extension NSCharacterSet {
    class func letter() -> NSCharacterSet {
        return self.letterCharacterSet()
    }
    class func whitespace() -> NSCharacterSet {
        return self.whitespaceCharacterSet()
    }
}

extension NSFileManager {
    func enumerator(atPath path: String) -> NSDirectoryEnumerator? {
        return self.enumeratorAtPath(path)
    }
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool,  attributes: [String : AnyObject]? = [:]) throws {
        return try self.createDirectoryAtPath(path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    func attributesOfItem(atPath path: String) throws -> [String : Any] {
        return try self.attributesOfItemAtPath(path)
    }
    func removeItem(atPath path: String) throws {
        return try self.removeItemAtPath(path)
    }
}

extension NSString {
    var deletingLastPathComponent: String {
        return self.stringByDeletingLastPathComponent
    }

    func substring(to index: Int) -> String {
        return self.substringToIndex(index)
    }
}
#endif
