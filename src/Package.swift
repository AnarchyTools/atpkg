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
            return lastComponent.toNSString.substringToIndex(lastComponent.characters.count - 4)
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

final public class Task {
    public var key: String = ""
    public var dependencies: [String] = []
    public var tool: String = "atllbuild"
    public var importedPath: String ///the directory at which the task was imported.  This includes a trailing /.

    var overlay: [String] = [] ///The overlays we should apply to this task
    var appliedOverlays: [String] = [] ///The overlays we did apply to this task

    var declaredOverlays: [String: [String: ParseValue]] = [:] ///The overlays this task declares

    public var allKeys: [String]

    private var kvp: [String:ParseValue]

    init?(value: ParseValue, name: String, importedPath: String) {
        guard let kvp = value.map else { return nil }
        self.importedPath = importedPath.pathWithTrailingSlash
        self.kvp = kvp
        self.key = name
        self.allKeys = [String](kvp.keys)
        self.tool = kvp["tool"]?.string ?? self.tool
        if let ol = kvp["overlay"] {
            guard let overlays = ol.vector else {
                fatalError("Non-vector overlay \(ol); did you mean to use `overlays` instead?")
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
                fatalError("Non-map overlays \(ol); did you mean to use `overlay` instead?")
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
        return kvp[key]
    }

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
                self.kvp[optionName] = ParseValue.Vector(newValue)
                //apply overlays to the model property
                if optionName == "overlay" {
                    for overlayName in vectorValue {
                        guard let overlayNameStr = overlayName.string else {
                            fatalError("Non-string overlayname \(overlayName)")
                        }
                        self.overlay.append(overlayNameStr)
                    }
                }

                case ParseValue.StringLiteral(let str):
                if let existingValue = self[optionName] {
                    fatalError("Can't overlay on \(self.key)[\(optionName)] which already has a value \(existingValue)")
                }
                self.kvp[optionName] = ParseValue.StringLiteral(str)

                case ParseValue.BoolLiteral(let b):
                if let existingValue = self[optionName] {
                    fatalError("Can't overlay on \(self.key)[\(optionName)] which already has a value \(existingValue)")
                }
                self.kvp[optionName] = ParseValue.BoolLiteral(b)


                default:
                fatalError("Canot overlay value \(optionValue); please file a bug")
            }
            

            
        }
        appliedOverlays.append(name)
        return overlay.keys.contains("overlay")
    }
}

final public class Package {
    // The required properties.
    public var name: String

    // The optional properties. All optional properties must have a default value.
    public var version: String = ""
    public var tasks: [String:Task] = [:]
    public var externals: [ExternalDependency] = []

    var overlays: [String: [String: ParseValue]] = [:]
    var adjustedImportPath: String = ""

    /**Calculate the pruned dependency graph for the given task
- returns: A list of tasks in a reasonable order to be processed. */
    public func prunedDependencyGraph(task: Task) -> [Task] {
        var pruned : [Task] = []
        if let dependencies = task["dependencies"]?.vector {
            for next in dependencies {
                guard let depName = next.string else { fatalError("Non-string dependency \(next)")}
                guard let nextTask = tasks[depName] else { fatalError("Can't find so-called task \(depName)")}
                let nextGraph = prunedDependencyGraph(nextTask)
                for nextItem in nextGraph {
                    let filteredTasks = pruned.filter() {$0.key == nextItem.key}
                    if filteredTasks.count >= 1 { continue }
                    pruned.append(nextItem)
                }
            }
        }
        pruned.append(task)
        return pruned
    }

    public init(name: String) {
        self.name = name
    }

    /**Create the package.
- parameter filepath: The path to the file to load
- parameter overlay: A list of overlays to apply globally to all tasks in the package. */
    public convenience init?(filepath: String, overlay: [String]) {
        guard let parser = Parser(filepath: filepath) else { return nil }

        do {
            let result = try parser.parse()
            let basepath = filepath.toNSString.stringByDeletingLastPathComponent
            self.init(type: result, overlay: overlay, pathOnDisk:basepath)
        }
        catch {
            print("error: \(error)")
            return nil
        }
    }

    public init?(type: ParseType, overlay requestedGlobalOverlays: [String], pathOnDisk: String) {
        if type.name != "package" { return nil }

        if let value = type.properties["name"]?.string { self.name = value }
        else {
            print("ERROR: No name specified for the package.")
            return nil
        }
        if let value = type.properties["version"]?.string { self.version = value }

        if let parsedTasks = type.properties["tasks"]?.map {
            for (key, value) in parsedTasks {
                if let task = Task(value: value, name: key, importedPath: pathOnDisk) {
                    self.tasks[key] = task
                }
            }
        }

        var remotePackages: [Package] = []

        //load remote packages
        if let imports = type.properties["import"]?.vector {
            for importFile in imports {
                guard let importFileString = importFile.string else { fatalError("Non-string import \(importFile)")}
                let adjustedImportPath = (pathOnDisk.pathWithTrailingSlash + importFileString).toNSString.stringByDeletingLastPathComponent.pathWithTrailingSlash
                let adjustedFileName = importFileString.toNSString.lastPathComponent
                guard let remotePackage = Package(filepath: adjustedImportPath + adjustedFileName, overlay: requestedGlobalOverlays) else {
                    fatalError("Can't load remote package \(adjustedImportPath + adjustedFileName)")
                }
                remotePackage.adjustedImportPath = adjustedImportPath
                remotePackages.append(remotePackage)
            }
        }

        // load external dependencies
        if let externalDeps = type.properties["externals"]?.vector {
            for dep in externalDeps {
                guard let d = dep.map else { fatalError("Non-Map external dependency declaration") }
                guard let url = d["url"]?.string else { fatalError("No URL in dependency declaration") }
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
                    externalDep = ExternalDependency(url: url, version: versionDecl)
                } else if let branch = d["branch"]?.string {
                    externalDep = ExternalDependency(url: url, branch: branch)
                } else if let commit = d["commit"]?.string {
                    externalDep = ExternalDependency(url: url, commit: commit)
                } else if let tag = d["tag"]?.string {
                    externalDep = ExternalDependency(url: url, tag: tag)
                }
                if let externalDep = externalDep {
                    // add to external deps
                    self.externals.append(externalDep)
                    let importFileString = "external/" + externalDep.name + "/build.atpkg"
                    
                    // import the atbuild file if it is there
                    let adjustedImportPath = (pathOnDisk.pathWithTrailingSlash + importFileString).toNSString.stringByDeletingLastPathComponent.pathWithTrailingSlash
                    let adjustedFileName = importFileString.toNSString.lastPathComponent
                    if let remotePackage = Package(filepath: adjustedImportPath + adjustedFileName, overlay: requestedGlobalOverlays) {
                        remotePackage.adjustedImportPath = adjustedImportPath
                        remotePackages.append(remotePackage)
                    } else {
                        print("Unsatisfied external dependency: \(externalDep.name), run atpm fetch")
                    }
                } else {
                    fatalError("Could not parse external dependency declaration for \(url)")
                }
            }
        }

        
        //load remote overlays
        for remotePackage in remotePackages {
            for (overlayName, value) in remotePackage.overlays {
                self.overlays["\(remotePackage.name).\(overlayName)"] = value
            }
        }
        if let ol = type.properties["overlays"] {
            guard let overlays = ol.map else {
                fatalError("Non-map overlay \(ol)")
            }
            for (name, overlay) in overlays {
                guard let innerOverlay = overlay.map else {
                    fatalError("Non-map overlay \(overlay)")
                }
                self.overlays[name] = innerOverlay
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
                        print("Warning: Can't apply overlay \(overlayName) to task \(task.key)")
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
                task.importedPath = remotePackage.adjustedImportPath
                task.key = "\(remotePackage.name).\(task.key)"
                self.tasks[task.key] = task
            }
        }


    }
}