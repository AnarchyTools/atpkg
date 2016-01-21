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
 * A task represents an action that can be performed by the `atbuild` system.
 */
final public class Task {
    /** This is the key the task is stored under in the package file. */
    public var key: String = ""
    
    /** This is all of the settings stored for the task. */
    public var config: ConfigMap = [:]
    
    /**
     * Initializes a new `Task` with the `key` and `config` set.
     */
    public init(key: String, config: ConfigMap) {
        self.key = key
        self.config = config
    }
    
//     public var dependencies: [String] = []
//     public var tool: String = "atllbuild"
//     public var importedPath: String ///the directory at which the task was imported.  This includes a trailing /.

//     var useOverlays: [String] = [] ///The overlays we should apply to this task
//     var appliedOverlays: [String] = [] ///The overlays we did apply to this task

//     var declaredOverlays: [String: [String: Value]] = [:] ///The overlays this task declares
    
//     public var allKeys: [String]
    
//     private var kvp: [String:Value]

//     init?(value: Value, name: String, importedPath: String) {
//         guard let kvp = value.map else { return nil }
//         self.importedPath = importedPath.pathWithTrailingSlash
//         self.kvp = kvp
//         self.key = name
//         self.allKeys = [String](kvp.keys)
//         self.tool = kvp["tool"]?.string ?? self.tool
//         if let ol = kvp["use-overlays"] {
//             guard let overlays = ol.vector else {
//                 fatalError("Non-vector overlay \(ol); did you mean to use `overlays` instead?")
//             }
//             for overlay in overlays {
//                 guard let str = overlay.string else {
//                     fatalError("Non-string overlay \(overlay)")
//                 }
//                 self.useOverlays.append(str)
//             }
//         }
//         if let ol = kvp["overlays"] {
//             guard let overlays = ol.map else {
//                 fatalError("Non-map overlays \(ol); did you mean to use `overlay` instead?")
//             }
//             for (name, overlay) in overlays {

//                 guard let innerOverlay = overlay.map else {
//                     fatalError("non-map overlay \(overlay)")
//                 }
//                 self.declaredOverlays[name] = innerOverlay
//             }
//         }

//         if let values = kvp["dependencies"]?.vector {
//             for value in values {
//                 if let dep = value.string { self.dependencies.append(dep) }
//             }
//         }
//     }
    
//     public subscript(key: String) -> Value? {
//         return kvp[key]
//     }

//     /**Apply the overlay to the receiver
// - warning: an overlay may itself apply another overlay.  In this case, the overlay for the task should be recalculated.
// - return: whether the overlay applied another overlay */
//     @warn_unused_result
//     private func applyOverlay(name: String, overlay: [String: Value]) -> Bool {
//         precondition(!appliedOverlays.contains(name), "Already applied overlay named \(name)")
//         for (optionName, optionValue) in overlay {
//             switch(optionValue) {
//                 case Value.Vector(let vectorValue):
//                 let existingValue: [Value]

//                 if let ev = self[optionName]?.vector  {
//                     existingValue = ev
//                 }
//                 else {
//                     existingValue = []
//                 }
//                 var newValue = existingValue
//                 newValue.appendContentsOf(vectorValue)
//                 self.kvp[optionName] = Value.Vector(newValue)
//                 //apply overlays to the model property
//                 if optionName == "use-overlays" {
//                     for overlayName in vectorValue {
//                         guard let overlayNameStr = overlayName.string else {
//                             fatalError("Non-string overlayname \(overlayName)")
//                         }
//                         self.useOverlays.append(overlayNameStr)
//                     }
//                 }

//                 case Value.StringLiteral(let str):
//                 if let existingValue = self[optionName] {
//                     fatalError("Can't overlay on \(self.key)[\(optionName)] which already has a value \(existingValue)")
//                 }
//                 self.kvp[optionName] = Value.StringLiteral(str)

//                 case Value.BoolLiteral(let b):
//                 if let existingValue = self[optionName] {
//                     fatalError("Can't overlay on \(self.key)[\(optionName)] which already has a value \(existingValue)")
//                 }
//                 self.kvp[optionName] = Value.BoolLiteral(b)


//                 default:
//                 fatalError("Canot overlay value \(optionValue); please file a bug")
//             }
            

            
//         }
//         appliedOverlays.append(name)
//         return overlay.keys.contains("use-overlays")
//     }
}

/**
 * A package is the structural represtation of an `atpkg` file.
 */
final public class Package {
    /** The keys used to store the values in the package file. */
    public enum Keys {
        public static let Name = "name"
        public static let Version = "version"
        public static let PackageTypeName = "package"
        public static let ImportPackages = "import-packages"
        public static let Tasks = "tasks"
    }
    
    /** The path to the package file. */
    public let path: String
    
    /** The imported packages. */
    public let importedPackages: [Package]
    
    /** This is the map of all of the settings stored for the package. */
    public let config: ConfigMap

    /** The name of the package. */
    public var name: String? {
        return config[Keys.Name]?.string
    }
    
    /** The version number for the package. */
    public var version: String? {
        return config[Keys.Version]?.string
    }
    
    /** The tasks for the package. */
    public var tasks: ConfigMap? {
        return config[Keys.Tasks]?.dictionary
    }
    
    /**
     * Initializes a new instance of `Package` from a given `DeclarationType`.
     * If `DeclarationType` does not specify a `package` declaration, the `nil`
     * will be returned.
     */
    private init(declarationType decl: DeclarationType, path: String) throws {
        if decl.name != Keys.PackageTypeName {
            throw PackageError(.InvalidDeclarationType(decl.name))
        }
        self.path = path
        self.config = decl.properties
        
        if let packages = config[Keys.ImportPackages] {
            guard let array = packages.array else {
                throw PackageError(.InvalidDataType(packages, Value.ArrayType))
            }
            
            let rootPath = (self.path as NSString).stringByDeletingLastPathComponent
            self.importedPackages = try array.map {
                guard let path = $0.string else {
                    throw PackageError(.InvalidDataType($0, Value.StringType))
                }
                
                return try Package(path: (rootPath as NSString).stringByAppendingPathComponent(path))
            }
        }
        else {
            self.importedPackages = []
        }
    }
    
    /**
     * Initializes a new instance of `Package` from the contents of the file
     * at the given `path`.
     */
    public convenience init(path: String) throws {
        guard let parser = Parser(path: path) else {
            throw PackageError(.InvalidPackageFilePath(path))
        }
        
        let decl = try parser.parse()
        try self.init(declarationType: decl, path: path)
    }
}
    
//     /** The mapping of overlays. */
//     var overlays: [String:ConfigMap] = [:]
    
    
    
    
//     var adjustedImportPath: String = ""

//     /**Calculate the pruned dependency graph for the given task
// - returns: A list of tasks in a reasonable order to be processed. */
//     public func prunedDependencyGraph(task: Task) -> [Task] {
//         var pruned : [Task] = []
//         if let dependencies = task["dependencies"]?.vector {
//             for next in dependencies {
//                 guard let depName = next.string else { fatalError("Non-string dependency \(next)")}
//                 guard let nextTask = tasks[depName] else { fatalError("Can't find so-called task \(depName)")}
//                 let nextGraph = prunedDependencyGraph(nextTask)
//                 for nextItem in nextGraph {
//                     let filteredTasks = pruned.filter() {$0.key == nextItem.key}
//                     if filteredTasks.count >= 1 { continue }
//                     pruned.append(nextItem)
//                 }
//             }
//         }
//         pruned.append(task)
//         return pruned
//     }
    
//     public init(name: String) {
//         self.name = name
//     }
    
//     /**Create the package.
// - parameter filepath: The path to the file to load
// - parameter overlay: A list of overlays to apply globally to all tasks in the package. */
//     public convenience init?(filepath: String, overlay: [String]) {
//         guard let parser = Parser(filepath: filepath) else { return nil }
        
//         do {
//             let result = try parser.parse()
//             let basepath = filepath.toNSString.stringByDeletingLastPathComponent
//             self.init(type: result, overlay: overlay, pathOnDisk:basepath)
//         }
//         catch {
//             print("error: \(error)")
//             return nil
//         }
//     }
    
//     public init?(type: DeclarationType, overlay requestedGlobalOverlays: [String], pathOnDisk: String) {
//         if type.name != "package" { return nil }
        
//         if let value = type.properties["name"]?.string { self.name = value }
//         else {
//             print("ERROR: No name specified for the package.")
//             return nil
//         }
//         if let value = type.properties["version"]?.string { self.version = value }

//         if let parsedTasks = type.properties["tasks"]?.map {
//             for (key, value) in parsedTasks {
//                 if let task = Task(value: value, name: key, importedPath: pathOnDisk) {
//                     self.tasks[key] = task
//                 }
//             }
//         }

//         var remotePackages: [Package] = []

//         //load remote packages
//         if let imports = type.properties["import"]?.vector {
//             for importFile in imports {
//                 guard let importFileString = importFile.string else { fatalError("Non-string import \(importFile)")}
//                 let adjustedImportPath = (pathOnDisk.pathWithTrailingSlash + importFileString).toNSString.stringByDeletingLastPathComponent.pathWithTrailingSlash
//                 let adjustedFileName = importFileString.toNSString.lastPathComponent
//                 guard let remotePackage = Package(filepath: adjustedImportPath + adjustedFileName, overlay: requestedGlobalOverlays) else {
//                     fatalError("Can't load remote package \(adjustedImportPath + adjustedFileName)")
//                 }
//                 remotePackage.adjustedImportPath = adjustedImportPath
//                 remotePackages.append(remotePackage)
//             }
//         }

//         //load remote overlays
//         for remotePackage in remotePackages {
//             for (overlayName, value) in remotePackage.overlays {
//                 self.overlays["\(remotePackage.name).\(overlayName)"] = value
//             }
//         }
//         if let ol = type.properties["overlays"] {
//             guard let overlays = ol.map else {
//                 fatalError("Non-map overlay \(ol)")
//             }
//             for (name, overlay) in overlays {
//                 guard let innerOverlay = overlay.map else {
//                     fatalError("Non-map overlay \(overlay)")
//                 }
//                 self.overlays[name] = innerOverlay
//             }
//         }

//         var usedGlobalOverlays : [String] = []
//         //swap in overlays

//         while true {
//             var again = false
//             for (_, task) in self.tasks {
//                 //merge task-declared and globally-declared overlays
//                 var declaredOverlays : [String: [String: Value]] = [:]
//                 for (k,v) in task.declaredOverlays {
//                     declaredOverlays[k] = v
//                 }
//                 for (k,v) in overlays {
//                     declaredOverlays[k] = v
//                 }

//                 for overlayName in task.useOverlays {
//                     if task.appliedOverlays.contains(overlayName) { continue }
//                     guard let overlay = declaredOverlays[overlayName] else {
//                         fatalError("Can't find overlay named \(overlayName) in \(declaredOverlays)")
//                     }
//                     again = again || task.applyOverlay(overlayName, overlay: overlay)
//                 }
//                 for overlayName in requestedGlobalOverlays {
//                     if task.appliedOverlays.contains(overlayName) { continue }

//                     guard let overlay = declaredOverlays[overlayName] else {
//                         print("Warning: Can't apply overlay \(overlayName) to task \(task.key)")
//                         continue
//                     }
//                     again = again || task.applyOverlay(overlayName, overlay: overlay)
//                     usedGlobalOverlays.append(overlayName)
//                 }
//             }
//             if !again { break }
//         }
        


//         //warn about unused global overlays
//         for requestedOverlay in requestedGlobalOverlays {
//             if !usedGlobalOverlays.contains(requestedOverlay) {
//                 print("Warning: overlay \(requestedOverlay) had no effect.")
//             }
//         }

//         //load remote tasks
//         for remotePackage in remotePackages {
//             for task in remotePackage.tasks.keys {
//                 remotePackage.tasks[task]!.importedPath = remotePackage.adjustedImportPath
//                 self.tasks["\(remotePackage.name).\(task)"] = remotePackage.tasks[task]
//             }
//         }


//     }
