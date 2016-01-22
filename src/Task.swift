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

    /** Initializes a new `Task` based on the given data. */
    public init(package: Package, key: String, config: ConfigMap) {
        self.package = package
        self.key = key
        self.config = config
    }
    
    /** A convenience for indexing into the `config` map. */
    public subscript(key: String) -> Value? {
        return self.config[key]
    }
    
    /**
     * Produces a new `ConfigMap` for the given task by merging together
     * all of the configuration information from the package.
     *
     * @param override An override `ConfigMap` used when merging the data.
     *                 This map will be treated as the highest priority map.
     */ 
    public func mergedConfig(config: ConfigMap? = nil) throws -> ConfigMap {
        let overlays = [
            config?[Package.Keys.UseOverlays]?.array,
            self.config[Package.Keys.UseOverlays]?.array
        ]
            .flatMap { $0 }
            .flatMap { $0 }
            .map { $0.string }
            .flatMap { $0 }
            
        let packageOverlays = try packageConfigs(package, overlays: overlays)
        
        let taskOverlays = try mergeConfigs(overlays.map {
            self.config[Package.Keys.Overlays]?.dictionary?[$0]?.dictionary
        }.flatMap { $0 })
        
        return try mergeConfigs([self.config, taskOverlays, packageOverlays, config].flatMap { $0 })
    }
    
    /**
     * Merges a set of config maps in reverse order of precedence.
     */
    private func mergeConfigs(configs: [ConfigMap]) throws -> ConfigMap {
        return try configs.reduce(ConfigMap()) { m1, m2 in
            var copy = m1
            for (key, value) in m2 {
                switch value {
                case .StringLiteral:
                    if copy[key]?.typeName == Value.StringType || copy[key]?.typeName == nil {
                        copy[key] = value
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.StringType))
                    }
                    
                case .IntegerLiteral:
                    if copy[key]?.typeName == Value.IntegerType || copy[key]?.typeName == nil {
                        copy[key] = value
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.IntegerType))
                    }

                case .FloatLiteral:
                    if copy[key]?.typeName == Value.FloatType || copy[key]?.typeName == nil {
                        copy[key] = value
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.FloatType))
                    }

                case .BoolLiteral:
                    if copy[key]?.typeName == Value.BoolType || copy[key]?.typeName == nil {
                        copy[key] = value
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.BoolType))
                    }
                    
                case let .ArrayLiteral(items):
                    if copy[key]?.typeName == Value.ArrayType || copy[key]?.typeName == nil {
                        var newItems = copy[key]?.array ?? []
                        for item in items {
                            newItems.append(item)
                        }
                        copy[key] = Value.ArrayLiteral(newItems)
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.ArrayType))
                    }
                    
                case let .DictionaryLiteral(items):
                    if copy[key]?.typeName == Value.DictionaryType || copy[key]?.typeName == nil {
                        let newItems = try mergeConfigs([copy[key]?.dictionary ?? [:], items])
                        copy[key] = Value.DictionaryLiteral(newItems)
                    }
                    else {
                        throw PackageError(.InvalidDataType(value, Value.DictionaryType))
                    }
                }
                
            }
            
            return copy
        }
    }

    private func packageConfigs(package: Package, overlays: [String]) throws -> ConfigMap {
        var merged = try mergeConfigs(overlays.map { package.overlays?[$0]?.dictionary }.flatMap { $0 })
        
        for package in package.importedPackages {
            merged = try mergeConfigs([packageConfigs(package, overlays: overlays), merged])
        }
        
        return merged
    }
}