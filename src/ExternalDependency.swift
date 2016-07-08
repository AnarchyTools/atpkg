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

final public class ExternalDependency {
    public enum VersioningMethod {
        case Version([String])
        case Commit(String)
        case Branch(String)
        case Tag(String)
    }
    public enum DependencyType {
        case Git
        case Manifest
    }

    ///- note: This may be an HTTP-style URL or a SSH-style URL
    public var url: String
    public var version: VersioningMethod
    public var channels: [String]?

    public var dependencyType: DependencyType

    ///atpm sets this value when it parses the name from the manifest.
    ///This value is then returned from `name` on request.
    ///Therefore, we "learn" the value of a remote package name after parsing its manifest.
    ///- warning: This API is particular to atpm, it is probably not useful unless you are working on that project
    public var _parsedNameFromManifest: String? = nil

    ///Custom info available for use by the application.
    ///In practice, this is used to hold lock information for atpm
    public var _applicationInfo: Any? = nil

    ///The name of the dependency.
    ///Note that if the dependency points to a manifest, the name is not known.
    public var name: String? {
        if self.dependencyType == .Manifest {
            if let p = _parsedNameFromManifest { return p }
            return nil
        }
        if let lastComponent = url.split(string: "/").last {
            if lastComponent.hasSuffix(".git") {
                return lastComponent.subString(toIndex: lastComponent.index(lastComponent.endIndex, offsetBy: -4))
            }
            return lastComponent
        } else {
            return nil
        }
    }

    private init?(url: String, versionMethod: VersioningMethod, channels: [String]?) {
        self.url = url
        self.version = versionMethod
        self.channels = channels
        if url.hasSuffix(".atpkg") {
            self.dependencyType = .Manifest
        }
        else { self.dependencyType = .Git }
        print("dependency type \(self.dependencyType)")
    }
    convenience init?(url: String, version: [String], channels: [String]?) {
        self.init(url: url, versionMethod: .Version(version), channels: channels)
    }

    convenience init?(url: String, commit: String, channels: [String]?) {
        self.init(url: url, versionMethod: .Commit(commit), channels: channels)
    }

    convenience init?(url: String, branch: String, channels: [String]?) {
        self.init(url: url, versionMethod: .Branch(branch), channels: channels)
    }

    convenience init?(url: String, tag: String, channels: [String]?) {
        self.init(url: url, versionMethod: .Tag(tag), channels: channels)
    }
}