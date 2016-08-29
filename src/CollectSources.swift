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
import atfoundation
/**
 * This function resolves wildcards in source descriptions to complete values
 *   - parameter sourceDescriptions: a descriptions of sources such as ["src/**.swift"] */
 *   - parameter taskForCalculatingPath: A task relative to which we calculate the path (to handle the import case).  If nil, we return what is listed in the atpkg.
 *   - returns: A list of resolved sources such as ["src/a.swift", "src/b.swift"]
 */
public func collectSources(sourceDescriptions: [String], taskForCalculatingPath task: Task?) -> [Path] {
    var sources : [Path] = []
    for unPrefixedDescription in sourceDescriptions {
        let description = (task?.importedPath ?? Path()) + unPrefixedDescription
        if unPrefixedDescription.hasSuffix("**.swift") {
            sources.append(contentsOf: findSources(basepath: description.dirname(),extension: ".swift"))
        }
        else if unPrefixedDescription.hasSuffix("**.c") {
            sources.append(contentsOf: findSources(basepath: description.dirname(),extension: ".c"))
        }
        else if unPrefixedDescription.hasSuffix("**.h") {
            sources.append(contentsOf: findSources(basepath: description.dirname(),extension: ".h"))
        }
        else {
            sources.append(description)
        }
    }
    return sources
}

private func findSources(basepath: Path, extension: String) -> [Path] {
    var sources: [Path] = []
    do {
        let iterator = try FS.iterateItems(path: basepath, recursive: true)
        for file in iterator {
            if file.path.components.last!.hasSuffix(`extension`) {
                sources.append(file.path)
            }
        }
    } catch {
        fatalError("Error: \(error) for '\(basepath)'")
    }
    return sources
}