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

enum PackageError: ErrorType {
    case NonVectorImport
    case ParserFailed
    case NonPackage
    case NoName
}
private extension Task {
 /**Apply the overlay to the receiver
- warning: an overlay may itself apply another overlay.  In this case, the overlay for the task should be recalculated.
- return: whether the overlay applied another overlay */
    @warn_unused_result
    private func applyOverlay(name: String, overlay: [String: ParseValue]) -> Bool {
        precondition(!appliedOverlays.contains(name), "Already applied overlay named \(name)")
        for (optionName, optionValue) in overlay {
            switch(optionValue) {
                case ParseValue.Vector(let vectorValue):
                let existingValue: [ParseValue]

                if let ev = self[optionName]?.vector  {
                    existingValue = ev
                }
                else {
                    existingValue = []
                }
                var newValue = existingValue
                newValue.appendContentsOf(vectorValue)
                self[optionName] = ParseValue.Vector(newValue)
                //apply overlays to the model property
                if optionName == "use-overlays" {
                    for overlayName in vectorValue {
                        guard let overlayNameStr = overlayName.string else {
                            fatalError("Non-string overlayname \(overlayName)")
                        }
                        self.overlay.append(overlayNameStr)
                    }
                }

                case ParseValue.StringLiteral(let str):
                if let existingValue = self[optionName] {
                    fatalError("Can't overlay on \(self.qualifiedName)[\(optionName)] which already has a value \(existingValue)")
                }
                self[optionName] = ParseValue.StringLiteral(str)

                case ParseValue.BoolLiteral(let b):
                if let existingValue = self[optionName] {
                    fatalError("Can't overlay on \(self.qualifiedName)[\(optionName)] which already has a value \(existingValue)")
                }
                self[optionName] = ParseValue.BoolLiteral(b)


                default:
                fatalError("Canot overlay value \(optionValue); please file a bug")
            }
        }
        appliedOverlays.append(name)
        return overlay.keys.contains("use-overlays")
    }
}

final public class Package {
    public enum Keys: String {
        case Name = "name"
        case Version = "version"
        case PackageTypeName = "package"
        case ImportPackages = "import-packages"
        case Tasks = "tasks"
        case Overlays = "overlays"
        case UseOverlays = "use-overlays"
    }
    
    // The required properties.
    public var name: String
    
    // The optional properties. All optional properties must have a default value.
    public var version: String = ""

    /**The tasks for the package.  For tasks in this package, they are indexed
    both by qualified and unqualified name.  For tasks in another package, they
    appear only by qualified name. */
    public var tasks: [String:Task] = [:]

    public var importedPath: String

    ///Overlays that are a (direct) child of the receiver.  These are indexed by unqualified name.
    private var childOverlays: [String: [String: ParseValue]] = [:]

    ///Overlays that are an (indirect) child of the receiver.  these are indexed by qualified name.
    private var importedOverlays: [String: [String: ParseValue]] = [:]

    ///The union of childOverlays and importedOverlays
    var overlays : [String: [String: ParseValue]] {
        var arr = childOverlays
        for (k,v) in importedOverlays {
            arr[k] = v
        }
        return arr
    }

    var adjustedImportPath: String = ""

    /**Calculate the pruned dependency graph for the given task
- returns: A list of tasks in a reasonable order to be processed. */
    public func prunedDependencyGraph(task: Task) -> [Task] {
        var pruned : [Task] = []
        if let dependencies = task["dependencies"]?.vector {
            for next in dependencies {
                guard let depName = next.string else { fatalError("Non-string dependency \(next)")}
                guard let nextTask = task.package.tasks[depName] else { fatalError("Can't find so-called task \(depName)")}
                let nextGraph = prunedDependencyGraph(nextTask)
                for nextItem in nextGraph {
                    let filteredTasks = pruned.filter() {$0.qualifiedName == nextItem.qualifiedName}
                    if filteredTasks.count >= 1 { continue }
                    pruned.append(nextItem)
                }
            }
        }
        pruned.append(task)
        return pruned
    }
    
    /**Create the package.
- parameter filepath: The path to the file to load
- parameter overlay: A list of overlays to apply globally to all tasks in the package. */
    public convenience init(filepath: String, overlay: [String]) throws {

        //todo: why doesn't this throw?
        guard let parser = Parser(filepath: filepath) else { throw PackageError.ParserFailed }
        
        let result = try parser.parse()
        let basepath = filepath.toNSString.stringByDeletingLastPathComponent
        try self.init(type: result, overlay: overlay, pathOnDisk:basepath)
    }
    
    public init(type: ParseType, overlay requestedGlobalOverlays: [String], pathOnDisk: String) throws {
        if type.name != "package" { throw PackageError.NonPackage }
        self.importedPath = pathOnDisk

        if let value = type.properties[Keys.Name.rawValue]?.string { self.name = value }
        else {
            throw PackageError.NoName
        }
        if let value = type.properties[Keys.Version.rawValue]?.string { self.version = value }

        if let parsedTasks = type.properties[Keys.Tasks.rawValue]?.map {
            for (name, value) in parsedTasks {
                if let task = Task(value: value, unqualifiedName: name, package: self, importedPath: pathOnDisk) {
                    self.tasks[task.unqualifiedName] = task
                    self.tasks[task.qualifiedName] = task
                }
            }
        }

        var remotePackages: [Package] = []

        //load remote packages
        if let imports_nv = type.properties[Keys.ImportPackages.rawValue] {
            guard let imports = imports_nv.vector else {
                throw PackageError.NonVectorImport
            }
            for importFile in imports {
                guard let importFileString = importFile.string else { fatalError("Non-string import \(importFile)")}
                let adjustedImportPath = (pathOnDisk.pathWithTrailingSlash + importFileString).toNSString.stringByDeletingLastPathComponent.pathWithTrailingSlash
                let adjustedFileName = importFileString.toNSString.lastPathComponent
                let remotePackage = try Package(filepath: adjustedImportPath + adjustedFileName, overlay: requestedGlobalOverlays)
                remotePackage.adjustedImportPath = adjustedImportPath
                remotePackages.append(remotePackage)
            }
        }

        //load remote overlays
        for remotePackage in remotePackages {
            for (overlayName, value) in remotePackage.childOverlays {
                self.importedOverlays["\(remotePackage.name).\(overlayName)"] = value
            }
            for (overlayName, value) in remotePackage.importedOverlays {
                self.importedOverlays[overlayName] = value
            }

        }
        if let ol = type.properties[Keys.Overlays.rawValue] {
            guard let overlays = ol.map else {
                fatalError("Non-map overlay \(ol)")
            }
            for (name, overlay) in overlays {
                guard let innerOverlay = overlay.map else {
                    fatalError("Non-map overlay \(overlay)")
                }
                self.childOverlays[name] = innerOverlay
            }
        }

        var usedGlobalOverlays : [String] = []
        //swap in overlays

        while true {
            var again = false
            for (_, task) in self.tasks {
                //merge task-declared and globally-declared overlays
                var declaredOverlays : [String: [String: ParseValue]] = [:]
                for (k,v) in task.declaredOverlays {
                    declaredOverlays[k] = v
                }
                for (k,v) in overlays {
                    declaredOverlays[k] = v
                }

                for overlayName in task.overlay {
                    if task.appliedOverlays.contains(overlayName) { continue }
                    guard let overlay = declaredOverlays[overlayName] else {
                        fatalError("Can't find overlay named \(overlayName) in \(declaredOverlays)")
                    }
                    again = again || task.applyOverlay(overlayName, overlay: overlay)
                }
                for overlayName in requestedGlobalOverlays {
                    if task.appliedOverlays.contains(overlayName) { continue }

                    guard let overlay = declaredOverlays[overlayName] else {
                        print("Warning: Can't apply overlay \(overlayName) to task \(task.qualifiedName)")
                        continue
                    }
                    again = again || task.applyOverlay(overlayName, overlay: overlay)
                    usedGlobalOverlays.append(overlayName)
                }
            }
            if !again { break }
        }

        //warn about unused global overlays
        for requestedOverlay in requestedGlobalOverlays {
            if !usedGlobalOverlays.contains(requestedOverlay) {
                print("Warning: overlay \(requestedOverlay) had no effect on package \(name)")
            }
        }

        //load remote tasks
        for remotePackage in remotePackages {
            for (_, task) in remotePackage.tasks {
                task.importedPath = task.package.adjustedImportPath
                self.tasks[task.qualifiedName] = task
            }
        }
    }
}