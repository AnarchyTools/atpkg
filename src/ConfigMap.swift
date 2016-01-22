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
 * A config map is a mapping of string values and config values. This is the
 * primary mechanism used for merging overlays.
 */
public typealias ConfigMap = [String:Value]

/**
 * Merges a set of config maps in reverse order of precedence.
 */
public func mergeConfigs(configs: [ConfigMap]) throws -> ConfigMap {
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

/**
 * Produces a `ConfigMap` based on the package data, the task to run, and the CLI
 * environment that's been given.
 */
public func overlayedConfigMap(package: Package, task: String, cli: ConfigMap? = nil) throws -> ConfigMap {
    guard let packageTask = package.tasks?[task] else {
        throw PackageError(.InvalidTask(task))
    }
    guard let task = packageTask.dictionary else {
        throw PackageError(.InvalidDataType(packageTask, Value.DictionaryType))
    }
    
    let overlays = [
        cli?[Package.Keys.UseOverlays]?.array,
        task[Package.Keys.UseOverlays]?.array
    ]
        .flatMap { $0 }
        .flatMap { $0 }
        .map { $0.string }
        .flatMap { $0 }
        
    let packageOverlays = try packageConfigs(package, overlays: overlays)
    
    let taskOverlays = try mergeConfigs(overlays.map {
        task[Package.Keys.Overlays]?.dictionary?[$0]?.dictionary
    }.flatMap { $0 })
    
    return try mergeConfigs([task, taskOverlays, packageOverlays, cli].flatMap { $0 })
}

private func packageConfigs(package: Package, overlays: [String]) throws -> ConfigMap {
    var merged = try mergeConfigs(overlays.map { package.overlays?[$0]?.dictionary }.flatMap { $0 })
    
    for package in package.importedPackages {
        merged = try mergeConfigs([packageConfigs(package, overlays: overlays), merged])
    }
    
    return merged
}