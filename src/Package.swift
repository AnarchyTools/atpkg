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

final public class Task {
    public var key: String = ""
    public var dependencies: [String] = []
    public var tool: String = "atllbuild"
    public var importedPath: String ///the directory at which the task was imported.  This includes a trailing /.

    var mixins: [String] = [] ///The mixins we should apply to this task
    
    public var allKeys: [String]
    
    private var kvp: [String:ParseValue]

    init?(value: ParseValue, name: String, importedPath: String) {
        guard let kvp = value.map else { return nil }
        self.importedPath = importedPath.pathWithTrailingSlash
        self.kvp = kvp
        self.key = name
        self.allKeys = [String](kvp.keys)
        self.tool = kvp["tool"]?.string ?? self.tool
        if let mixins = kvp["mixins"]?.vector {
            for mixin in mixins {
                guard let str = mixin.string else {
                    fatalError("Non-string mixin \(mixin)")
                }
                self.mixins.append(str)
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
}

final public class Package {
    // The required properties.
    public var name: String
    
    // The optional properties. All optional properties must have a default value.
    public var version: String = ""
    public var tasks: [String:Task] = [:]

    var mixins: [String: ParseValue] = [:]
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
    
    public convenience init?(filepath: String, configurations: [String: String] = [:]) {
        guard let parser = Parser(filepath: filepath) else { return nil }
        
        do {
            let result = try parser.parse()
            let basepath = filepath.toNSString.stringByDeletingLastPathComponent
            self.init(type: result, configurations: configurations, pathOnDisk:basepath)
        }
        catch {
            print("error: \(error)")
            return nil
        }
    }
    
    public init?(type: ParseType, configurations: [String: String], pathOnDisk: String) {
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

        //swap in configurations
        var usedConfigurations : [String] = []
        for requestedConfiguration in configurations.keys {
            for (taskname, task) in self.tasks {
                if let configurationSpecs = task.kvp["configurations"]?.map {
                    if let activeConfiguration = configurationSpecs[requestedConfiguration]?.vector {
                        for mixin in activeConfiguration {
                            guard let str = mixin.string else {
                                fatalError("Non-string mixin \(mixin)")
                            }
                            task.mixins.append(str)
                            usedConfigurations.append(requestedConfiguration)
                        }
                    }
                }
            }
        }
        //warn about unused configurations
        for requestedConfiguration in configurations.keys {
            if !usedConfigurations.contains(requestedConfiguration) {
                print("Warning: configuration \(requestedConfiguration) had no effect.")
            }
        }

        var remotePackages: [Package] = []

        //load remote packages
        if let imports = type.properties["import"]?.vector {
            for importFile in imports {
                guard let importFileString = importFile.string else { fatalError("Non-string import \(importFile)")}
                let adjustedImportPath = (pathOnDisk.pathWithTrailingSlash + importFileString).toNSString.stringByDeletingLastPathComponent.pathWithTrailingSlash
                let adjustedFileName = importFileString.toNSString.lastPathComponent
                guard let remotePackage = Package(filepath: adjustedImportPath + adjustedFileName, configurations: configurations) else {
                    fatalError("Can't load remote package \(adjustedImportPath + adjustedFileName)")
                }
                remotePackage.adjustedImportPath = adjustedImportPath
                remotePackages.append(remotePackage)
            }
        }

        //load remote mixins
        for remotePackage in remotePackages {
            for (mixinName, value) in remotePackage.mixins {
                self.mixins["\(remotePackage.name).\(mixinName)"] = value
            }
        }
        
        if let mixins = type.properties["mixins"]?.map {
            for (name, mixin) in mixins {
                self.mixins[name] = mixin
            }
        }

        //swap in mixins
        for (name, task) in self.tasks {
            for mixinName in task.mixins {
                guard let mixin = mixins[mixinName]?.map else {
                    fatalError("Can't find mixin named \(mixinName) in \(mixins)")
                }
                for (optionName, optionValue) in mixin {
                    guard let vectorValue = optionValue.vector else {
                        fatalError("Unsupported non-vector type \(optionValue)")
                    }
                    guard let existingValue = task[optionName]?.vector else {
                        fatalError("Can't mixin to \(task.key)[\(optionName)]")
                    }

                    guard let optionValueVec = optionValue.vector else {
                        fatalError("Non-vector option value \(optionValue)")
                    }
                    var newValue = existingValue
                    newValue.appendContentsOf(optionValueVec)
                    task.kvp[optionName] = ParseValue.Vector(newValue)
                }
            }
        }

        //load remote tasks
        for remotePackage in remotePackages {
            for task in remotePackage.tasks.keys {
                remotePackage.tasks[task]!.importedPath = remotePackage.adjustedImportPath
                self.tasks["\(remotePackage.name).\(task)"] = remotePackage.tasks[task]
            }
        }


    }
}