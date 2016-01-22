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
 * A `Task` is the structural represtation of an `atpkg` file.
 */
public final class Task {
    /** The package that the task belongs to. */
    public let package: Package
    
    /** This is the map of all of the settings stored for the task. */
    public let config: ConfigMap

    /** The key the task is stored within the package. */
    public let key: String

    public init(package: Package, key: String, config: ConfigMap) {
        self.package = package
        self.key = key
        self.config = config
    }
}