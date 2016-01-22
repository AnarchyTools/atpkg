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
 * A `Package` is the structural represtation of an `atpkg` file.
 */
final public class Package {
    /** The file extension for all packages. */
    public static let PackageExtension = "atpkg"
    
    /** The keys used to store the values in the package file. */
    public enum Keys {
        public static let Name = "name"
        public static let Version = "version"
        public static let PackageTypeName = "package"
        public static let ImportPackages = "import-packages"
        public static let Tasks = "tasks"
        public static let Overlays = "overlays"
        public static let UseOverlays = "use-overlays"
    }
    
    /** The path to the package file. */
    public let path: String

    /** The file name of the package file. */
    public let fileName: String
    
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
    public var tasks: [String:Task] {
        if _tasks == nil {
            _tasks = [:]
            for (key, value) in config[Keys.Tasks]?.dictionary ?? [:] {
                _tasks?[key] = Task(package: self, key: key, config: value.dictionary!)
            }
            
            findImportedTasks(self.importedPackages)
        }
        return _tasks!
    }
    private var _tasks: [String:Task]? = nil
    
    private func findImportedTasks(packages: [Package]) {
        if _tasks == nil { _tasks = [:] }
        for package in packages {
            for (key, task) in package.tasks {
                _tasks?["\(package.name!)/\(key)"] = task
            }
            findImportedTasks(package.importedPackages)
        }
    }


    /** The overlays for the package. */
    public var overlays: ConfigMap? {
        return config[Keys.Overlays]?.dictionary
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
        self.path = path.toNSString.stringByDeletingLastPathComponent
        self.fileName = path.toNSString.lastPathComponent
        self.config = decl.properties
        
        if let packages = config[Keys.ImportPackages] {
            guard let array = packages.array else {
                throw PackageError(.InvalidDataType(packages, Value.ArrayType))
            }
            
            let basePath = self.path
            self.importedPackages = try array.map {
                guard let path = $0.string else {
                    throw PackageError(.InvalidDataType($0, Value.StringType))
                }
                
                return try Package(path: basePath.toNSString.stringByAppendingPathComponent(path) + ".\(Package.PackageExtension)")
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

extension Package {
    /**
     * Calculate the pruned dependency graph for the given task
     *
     * - returns: A list of tasks in a reasonable order to be processed.
     */
    public func prunedDependencyGraph(task: Task) -> [Task] {
        var pruned : [Task] = []
        if let dependencies = task["dependencies"]?.array {
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
}
