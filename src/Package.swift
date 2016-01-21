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
            
            let rootPath = self.path.toNSString().stringByDeletingLastPathComponent
            self.importedPackages = try array.map {
                guard let path = $0.string else {
                    throw PackageError(.InvalidDataType($0, Value.StringType))
                }
                
                return try Package(path: rootPath.toNSString().stringByAppendingPathComponent(path))
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
