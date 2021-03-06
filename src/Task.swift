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

final public class Task {
    ///The unqualified name of the task, not including its package name
    public let unqualifiedName: String

    ///The qualified name of the task, including its package name
    public var qualifiedName: String {
        return package.name + "." + unqualifiedName
    }

    ///The package for the task
    public let package: Package

    public var dependencies: [String] = []
    public var tool: String
    public var importedPath: Path /// the directory at which the task was imported

    var overlay: [String] = [] ///The overlays we should apply to this task
    internal(set) public var appliedOverlays: [String] = [] ///The overlays we did apply to this task

    var declaredOverlays: [String: [String: ParseValue]] = [:] ///The overlays this task declares

    public var allKeys: [String] {
        return [String](self.kvp.keys)
    }

    private var kvp: [String:ParseValue]

    public var onlyPlatforms: [String] = []

    public enum Option: String {
        case Tool = "tool"
        case UseOverlays = "use-overlays"
        case Overlays = "overlays"
        case Dependencies = "dependencies"
        case OnlyPlatforms = "only-platforms"

        public static var allOptions: [Option] {
            return [
                    Tool,
                    UseOverlays,
                    Overlays,
                    Dependencies,
                    OnlyPlatforms
            ]
        }
    }

    init?(value: ParseValue, unqualifiedName: String, package: Package, importedPath: Path) {
        precondition(!unqualifiedName.characters.contains("."), "Task \(unqualifiedName) may not contain a period.")
        guard let kvp = value.map else { return nil }
        self.importedPath = importedPath
        self.kvp = kvp
        self.unqualifiedName = unqualifiedName
        self.package = package

        guard let tool = kvp[Option.Tool.rawValue]?.string else {
            self.tool = "invalid"
            fatalError("No tool for task \(qualifiedName); did you forget to specify it?")
        }
        self.tool = tool

        if let ol = kvp[Option.UseOverlays.rawValue] {
            guard let overlays = ol.vector else {
                fatalError("Non-vector \(Option.UseOverlays.rawValue) \(ol); did you mean to use `\(Option.Overlays.rawValue)` instead?")
            }
            for overlay in overlays {
                guard let str = overlay.string else {
                    fatalError("Non-string overlay \(overlay)")
                }
                self.overlay.append(str)
            }
        }
        if let ol = kvp[Option.Overlays.rawValue] {
            guard let overlays = ol.map else {
                fatalError("Non-map \(Option.Overlays.rawValue) \(ol); did you mean to use `\(Option.UseOverlays.rawValue)` instead?")
            }
            for (name, overlay) in overlays {

                guard let innerOverlay = overlay.map else {
                    fatalError("non-map overlay \(overlay)")
                }
                self.declaredOverlays[name] = innerOverlay
            }
        }

        if let values = kvp[Option.Dependencies.rawValue]?.vector {
            for value in values {
                if let dep = value.string { self.dependencies.append(dep) }
            }
        }

        if let onlyPlatforms = kvp[Option.OnlyPlatforms.rawValue] {
            guard let o = onlyPlatforms.vector else { fatalError("Non-vector \(Option.OnlyPlatforms.rawValue) \(onlyPlatforms)")}
            for o in o {
                guard case .StringLiteral(let platform) = o else { fatalError("Non-string \(Option.OnlyPlatforms.rawValue) \(o)")}
                self.onlyPlatforms.append(platform)
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

    ///Checks that the required overlays in the task are present. We
    ///allow the parsing of a file that is missing some overlays since
    ///those overlays may not be required for the present task.
    public func checkRequiredOverlays() throws {
            if let requiredOverlays_v = self["required-overlays"] {
                guard let requiredOverlays = requiredOverlays_v.vector else {
                    fatalError("Non-vector \(requiredOverlays_v)")
                }
                nextSet: for overlaySet_v in requiredOverlays {
                    guard let overlaySet = overlaySet_v.vector else {
                        fatalError("Non-vector \(overlaySet_v)")
                    }
                    for overlay_s in overlaySet {
                        guard let overlay = overlay_s.string else {
                            fatalError("Non-string \(overlay_s)")
                        }
                        if self.appliedOverlays.contains(overlay) { continue nextSet }
                    }
                    print("Task \(self.qualifiedName) requires at least one of \(overlaySet.map() {$0.string}) but it was not applied.  Applied overlays: \(self.appliedOverlays)")
                    throw PackageError.RequiredOverlayNotPresent(overlaySet.map() {$0.string!})
                }
            }
    }
}