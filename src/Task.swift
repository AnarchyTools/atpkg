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

final public class Task {
    ///The unqualified name of the task, not including its package name
    public let unqualifiedName: String

    ///The qualified name of the task, including its package name
    public var qualifiedName: String {
        return package.name + "." + unqualifiedName
    }

    ///The package for the task
    let package: Package

    public var dependencies: [String] = []
    public var tool: String
    public var importedPath: String ///the directory at which the task was imported.  This includes a trailing /.

    var overlay: [String] = [] ///The overlays we should apply to this task
    var appliedOverlays: [String] = [] ///The overlays we did apply to this task

    var declaredOverlays: [String: [String: ParseValue]] = [:] ///The overlays this task declares
    
    public var allKeys: [String]
    
    private var kvp: [String:ParseValue]

    init?(value: ParseValue, unqualifiedName: String, package: Package, importedPath: String) {
        precondition(!unqualifiedName.characters.contains("."), "Task \(unqualifiedName) may not contain a period.")
        guard let kvp = value.map else { return nil }
        self.importedPath = importedPath.pathWithTrailingSlash
        self.kvp = kvp
        self.unqualifiedName = unqualifiedName
        self.package = package
        self.allKeys = [String](kvp.keys)

        guard let tool = kvp["tool"]?.string else {
            self.tool = "invalid"
            fatalError("No tool for task \(qualifiedName); did you forget to specify it?")
        }
        self.tool = tool

        if let ol = kvp["use-overlays"] {
            guard let overlays = ol.vector else {
                fatalError("Non-vector use-overlays \(ol); did you mean to use `overlays` instead?")
            }
            for overlay in overlays {
                guard let str = overlay.string else {
                    fatalError("Non-string overlay \(overlay)")
                }
                self.overlay.append(str)
            }
        }
        if let ol = kvp["overlays"] {
            guard let overlays = ol.map else {
                fatalError("Non-map overlays \(ol); did you mean to use `use-overlays` instead?")
            }
            for (name, overlay) in overlays {

                guard let innerOverlay = overlay.map else {
                    fatalError("non-map overlay \(overlay)")
                }
                self.declaredOverlays[name] = innerOverlay
            }
        }

        if let values = kvp["dependencies"]?.vector {
            for value in values {
                if let dep = value.string { self.dependencies.append(dep) }
            }
        }
    }
    
    public subscript(key: String) -> ParseValue? {
        get {
            return kvp[key]
        }
        set {
            kvp[key] = newValue
        }
    }
}