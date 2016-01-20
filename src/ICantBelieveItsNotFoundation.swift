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
    public func stringByReplacingOccurrencesOfString(target: String, withString replacement: String) -> String {
        return self.bridge().stringByReplacingOccurrencesOfString(target, withString: replacement)
    }

    public func subStringWithRange(range: Range<String.Index>) -> String {
        var result = ""
        result.reserveCapacity(range.count)
        for idx in range {
            result.append(self.characters[idx])
        }
        return result
    }
    
    public func substringToIndex(index: Int) -> String {
        return self.subStringWithRange(self.startIndex..<self.startIndex.advancedBy(index))
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

//enumeratorAtPath isn't implemented
//https://github.com/apple/swift-corelibs-foundation/pull/232 upstreams this code.
class ICantBelieveItsNotNSDirectoryEnumerator {
    let baseURL: NSURL
    let innerEnumerator : NSDirectoryEnumerator
    var fileAttributes: [String : AnyObject]? {
        fatalError("Not implemented")
    }
    var directoryAttributes: [String : AnyObject]? {
        fatalError("Not implemented")
    }
    
    /* This method returns the number of levels deep the current object is in the directory hierarchy being enumerated. The directory passed to -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: is considered to be level 0.
     */
    var level: Int {
        fatalError("Not implemented")
    }
    
    func skipDescendants() {
        fatalError("Not implemented")
    }
    
    init?(path: String) {
        let url = NSURL(fileURLWithPath: path)
        self.baseURL = url
        guard let ie = NSFileManager.defaultManager().enumeratorAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(), errorHandler: nil) else {
            return nil
        }
        self.innerEnumerator = ie
    }
    
    func nextObject() -> AnyObject? {
        let o = innerEnumerator.nextObject()
        guard let url = o as? NSURL else {
            return nil
        }
        let path = url.path!.stringByReplacingOccurrencesOfString(baseURL.path!+"/", withString: "")
        return NSString(string: path)
    }
    
}
func ICantBelieveItsNotFoundation_enumeratorAtPath(path: String) -> ICantBelieveItsNotNSDirectoryEnumerator? {
    return ICantBelieveItsNotNSDirectoryEnumerator(path: path)
}
