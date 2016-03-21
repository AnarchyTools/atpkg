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

final public class ExternalDependency {
    public enum VersioningMethod {
        case Version([String])
        case Commit(String)
        case Branch(String)
        case Tag(String)
    }

    public var gitURL: String
    public var version: VersioningMethod

    public var name: String {
        let lastComponent = gitURL.toNSString.lastPathComponent
        if lastComponent.hasSuffix(".git") {
            return lastComponent.toNSString.substring(to: lastComponent.characters.count - 4)
        }
        return lastComponent
    }

    init?(url: String, version: [String]) {
        self.gitURL = url
        self.version = .Version(version)
    }

    init?(url: String, commit: String) {
        self.gitURL = url
        self.version = .Commit(commit)
    }

    init?(url: String, branch: String) {
        self.gitURL = url
        self.version = .Branch(branch)
    }

    init?(url: String, tag: String) {
        self.gitURL = url
        self.version = .Tag(tag)
    }
}