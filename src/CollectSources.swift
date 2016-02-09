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
/**
 * This function resolves wildcards in source descriptions to complete values
 *   - parameter sourceDescriptions: a descriptions of sources such as ["src/**.swift"] */
 *   - parameter taskForCalculatingPath: A task relative to which we calculate the path (to handle the import case).  If nil, we return what is listed in the atpkg.
 *   - returns: A list of resolved sources such as ["src/a.swift", "src/b.swift"]
 */
public func collectSources(sourceDescriptions: [String], taskForCalculatingPath task: Task?) -> [String] {
    var sources : [String] = []
    for unPrefixedDescription in sourceDescriptions {
        let description = (task?.importedPath ?? "") + unPrefixedDescription
        if description.hasSuffix("**.swift") {
            let basepath = String(Array(description.characters)[0..<description.characters.count - 9])
            let manager = NSFileManager.defaultManager()
            guard let enumerator = manager.enumeratorAtPath(basepath) else {
                fatalError("Invalid path \(basepath)")
            }
            while let source_ns = enumerator.nextObject() as? NSString {
                let source = source_ns.toString
                if source.hasSuffix("swift") {
                    sources.append(basepath + "/" + source)
                }
            }
        }
        else {
            sources.append(description)
        }
    }
    return sources
}