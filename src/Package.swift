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

enum PackageError: Error {
    case NonVectorImport
    case ParserFailed
    case NonPackage
    case NoName
    case RequiredOverlayNotPresent([String])
}

fileprivate func merge(_ lhs: ParseValue, _ rhs: ParseValue) -> ParseValue {
    switch(lhs, rhs) {
        case (.Vector(let l), .Vector(let r)):
        return .Vector(l + r)

        default:
        fatalError("Can't merge \(lhs) and \(rhs)")
    }
}
fileprivate extension Task {
 /**Apply the overlay to the receiver
- warning: an overlay may itself apply another overlay.  In this case, the overlay for the task should be recalculated.
- return: whether the overlay applied another overlay */
    fileprivate func applyOverlay(name: String, overlay: [String: ParseValue], globalOverlays: [String]) -> Bool {
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
                newValue.append(contentsOf: vectorValue)
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

                case ParseValue.Map(let m):
                precondition(optionName == "overlays", "Don't support map merging for key \(optionName)")
                for key in m.keys {
                    if globalOverlays.contains(key) {
                        for (key, value) in m[key]!.map! {
                            if let existingValue = self[key] {
                                self[key] = merge(existingValue, value)
                            }
                            else {
                                self[key] = value
                            }
                        }
                        
                    }
                }

                default:
                fatalError("Canot overlay value \(optionValue); please file a bug")
            }
        }
        appliedOverlays.append(name)
        return overlay.keys.contains("use-overlays")
    }
}

final public class Package {
    public enum Key: String {
        case Name = "name"
        case Version = "version"
        case PackageTypeName = "package"
        case ImportPackages = "import-packages"
        case ExternalPackages = "external-packages"
        case Tasks = "tasks"
        case Overlays = "overlays"
        case UseOverlays = "use-overlays"
        case Payload = "payload"
        case Binaries = "binaries"
        case BinaryChannels = "channels"

        static var allKeys: [Key] {
            return [
                    Name,
                    Version,
                    PackageTypeName,
                    ImportPackages,
                    ExternalPackages,
                    Tasks,
                    Overlays,
                    UseOverlays,
                    Binaries,
                    BinaryChannels,
					Payload
            ]
        }
    }

    // The required properties.
    public var name: String

    // The optional properties. All optional properties must have a default value.
    public var version: String? = nil

    ///The binary payload, if the package is an atbin
    public var payload: String? = nil

    /**The tasks for the package.  For tasks in this package, they are indexed
    both by qualified and unqualified name.  For tasks in another package, they
    appear only by qualified name. */
    public var tasks: [String:Task] = [:]
    public var externals: [ExternalDependency] = []

    public var importedPath: Path

    ///Overlays that are a (direct) child of the receiver.  These are indexed by unqualified name.
    private var childOverlays: [String: [String: ParseValue]] = [:]

    ///Overlays that are an (indirect) child of the receiver.  these are indexed by qualified name.
    private var importedOverlays: [String: [String: ParseValue]] = [:]

    public var binaryChannels : [BinaryChannel]?

    ///The union of childOverlays and importedOverlays
    var overlays : [String: [String: ParseValue]] {
        var arr = childOverlays
        for (k,v) in importedOverlays {
            arr[k] = v
        }
        return arr
    }

    var adjustedImportPath: Path = Path()

    /**Calculate the pruned dependency graph for the given task
- returns: A list of tasks in a reasonable order to be processed. */
    public func prunedDependencyGraph(task: Task) -> [Task] {
        var pruned : [Task] = []
        if let dependencies = task["dependencies"]?.vector {
            for next in dependencies {
                guard let depName = next.string else { fatalError("Non-string dependency \(next)")}
                guard let nextTask = task.package.tasks[depName] else { fatalError("Can't find so-called task \(depName)")}
                let nextGraph = prunedDependencyGraph(task: nextTask)
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
    - parameter pathOnDisk: The path to the file on disk.  This does not include the file name.
    - parameter overlay: A list of overlays to apply globally to all tasks in the package.
    - parameter focusOnTask: The user has "selected" the particular task.  We provide more diagnostics for this task.
*/
    public convenience init(filepath: Path, overlay: [String], focusOnTask: String?, softFail: Bool = true) throws {

        //todo: why doesn't this throw?
        guard let parser = try Parser(filepath: filepath) else {
            throw PackageError.ParserFailed
        }

        let result = try parser.parse()
        let basepath = filepath.dirname()
        try self.init(type: result, overlay: overlay, pathOnDisk:basepath, focusOnTask: focusOnTask, softFail: softFail)
    }

    /**
    - parameter overlay: The names of things to overlay.
    - parameter pathOnDisk: The path to the file on disk.  This does not include the file name.
    - parameter focusOnTask: The user has "selected" the particular task.  We provide more diagnostics for this task.
    - parameter softFail: Don't fail hard on certain kinds of errors that may occur if dependencies are not fetched
    */
    public init(type: ParseType, overlay requestedGlobalOverlays: [String], pathOnDisk: Path, focusOnTask: String?, softFail: Bool = false) throws {
        //warn on unknown keys
        for (k,_) in type.properties {
            if !Key.allKeys.map({$0.rawValue}).contains(k) {
                print("Warning: unknown package key \(k)")
            }
        }

        if type.name != "package" { throw PackageError.NonPackage }
        self.importedPath = pathOnDisk

        if let value = type.properties[Key.Name.rawValue]?.string { self.name = value }
        else {
            throw PackageError.NoName
        }
        if let value = type.properties[Key.Version.rawValue]?.string { self.version = value }

        if let parsedTasks = type.properties[Key.Tasks.rawValue]?.map {
            for (name, value) in parsedTasks {
                if let task = Task(value: value, unqualifiedName: name, package: self, importedPath: pathOnDisk) {
                    self.tasks[task.unqualifiedName] = task
                    self.tasks[task.qualifiedName] = task
                }
            }
        }

        if let payload = type.properties[Key.Payload.rawValue]?.string {
            self.payload = payload
        }

        var remotePackages: [Package] = []

        //load remote packages
        if let imports_nv = type.properties[Key.ImportPackages.rawValue] {
            guard let imports = imports_nv.vector else {
                throw PackageError.NonVectorImport
            }
            for importFile in imports {
                guard let importFileString = importFile.string else { fatalError("Non-string import \(importFile)")}
                let adjustedImportPath = (pathOnDisk + importFileString).dirname()
                let remotePackage = try Package(filepath: pathOnDisk + importFileString, overlay: requestedGlobalOverlays, focusOnTask: nil, softFail: softFail)
                remotePackage.adjustedImportPath = adjustedImportPath
                remotePackages.append(remotePackage)
            }
        }

        // load external dependencies
        if let externalDeps = type.properties["external-packages"]?.vector {
            for dep in externalDeps {
                guard let d = dep.map else { fatalError("Non-Map external dependency declaration") }
                guard let url = d["url"]?.string else { fatalError("No URL in dependency declaration") }
                let channels: [String]?
                if let c = d["channels"] {
                    var channels_ : [String] = []
                    guard case .Vector(let v) = c else { fatalError("Non-vector channel specification")}
                    for cs in v {
                        guard case .StringLiteral(let s) = cs else { fatalError("Non-string channel specifier \(cs)")}
                        channels_.append(s)
                    }
                    channels = channels_
                }
                else { channels = nil }
                var externalDep: ExternalDependency? = nil
                if let version = d["version"]?.vector {
                    var versionDecl = [String]()
                    for ver in version {
                        if let v = ver.string {
                            versionDecl.append(v)
                        } else {
                            fatalError("Could not parse external dependency version declaration for \(url)")
                        }
                    }
                    externalDep = ExternalDependency(url: url, version: versionDecl, channels: channels, package: self)
                } else if let branch = d["branch"]?.string {
                    externalDep = ExternalDependency(url: url, branch: branch, channels: channels, package: self)
                } else if let commit = d["commit"]?.string {
                    externalDep = ExternalDependency(url: url, commit: commit, channels: channels, package: self)
                } else if let tag = d["tag"]?.string {
                    externalDep = ExternalDependency(url: url, tag: tag, channels: channels, package: self)
                }
                if let externalDep = externalDep {

                    if let iiv = d["if-including"] {
                        guard case .Vector(let ii) = iiv else {
                            fatalError("Non-vector if-including directive \(iiv)")
                        }
                        externalDep.ifIncluding = []
                        for iss in ii {
                            guard case .StringLiteral(let s) = iss else {
                                fatalError("Non-string if-including directive \(iss)")
                            }
                            externalDep.ifIncluding!.append(s)
                        }
                    }

                    // add to external deps
                    self.externals.append(externalDep)

                    switch(externalDep.dependencyType) {
                        case .Git:
                        let importFileString = "external/" + externalDep.name! + "/build.atpkg"

                        // import the atbuild file if it is there
                        let adjustedImportPath = (pathOnDisk + importFileString).dirname()
                        do {
                            let remotePackage = try Package(filepath: pathOnDisk + importFileString, overlay: requestedGlobalOverlays, focusOnTask: nil, softFail: softFail)
                            remotePackage.adjustedImportPath = adjustedImportPath
                            remotePackages.append(remotePackage)
                        } catch {
                            print("Unsatisfied external dependency: \(externalDep.name!) (Error: \(error)), run atpm fetch")
                        }

                        case .Manifest:
                        //we don't import the package in this case
                        break
                    }
                    
                } else {
                    fatalError("Could not parse external dependency declaration for \(url)")
                }
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
        if let ol = type.properties[Key.Overlays.rawValue] {
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

        var warnings: [String] = []
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
                        if softFail {
                            let proposedWarning = "Warning: Can't find overlay named \(overlayName) in \(declaredOverlays); run atpm fetch"
                            if !warnings.contains(proposedWarning) { warnings.append(proposedWarning) }
                            continue
                        }
                        else {
                            fatalError("Can't find overlay named \(overlayName) in \(declaredOverlays)")
                        }
                    }
                    again = again || task.applyOverlay(name: overlayName, overlay: overlay, globalOverlays: requestedGlobalOverlays)
                }
                for overlayName in requestedGlobalOverlays {
                    if task.appliedOverlays.contains(overlayName) { continue }

                    guard let overlay = declaredOverlays[overlayName] else {
                        if focusOnTask == task.unqualifiedName || focusOnTask == task.qualifiedName {
                            if !overlayName.hasPrefix("at.") && !overlayName.hasPrefix("atbuild.") {
                                let proposedWarning = "Warning: Can't apply overlay \(overlayName) to task \(task.qualifiedName)"
                                if !warnings.contains(proposedWarning) { warnings.append(proposedWarning) }
                            }
                        }
                        continue
                    }
                    again = again || task.applyOverlay(name: overlayName, overlay: overlay, globalOverlays: requestedGlobalOverlays)
                    usedGlobalOverlays.append(overlayName)
                }
            }
            if !again { break }
        }
        for warning in warnings {
            print(warning)
        }

        //warn about unused global overlays
        for requestedOverlay in requestedGlobalOverlays {
            if !usedGlobalOverlays.contains(requestedOverlay) {
                if !requestedOverlay.hasPrefix("atbuild.") && !requestedOverlay.hasPrefix("at.") {
                    print("Warning: overlay \(requestedOverlay) had no effect on package \(name)")
                }
            }
        }

        //load remote tasks
        for remotePackage in remotePackages {
            for (_, task) in remotePackage.tasks {
                task.importedPath = task.package.adjustedImportPath
                self.tasks[task.qualifiedName] = task
            }
        }

        //load binary channels
        if let binaries = type.properties[Key.Binaries.rawValue]?.map, let channels = binaries[Key.BinaryChannels.rawValue] {
            self.binaryChannels = BinaryChannel.parse(channels)
        }
        else { self.binaryChannels = nil }
    }
}