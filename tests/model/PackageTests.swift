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
import AnarchyPackage

class PackageTests: Test {
    required init() {}
    let tests = [
        PackageTests.testBasic,
        PackageTests.testImport,
        // PackageTests.testMergeConfigs,
        // PackageTests.testInvalidMergeConfigs,
        PackageTests.testOverlays,
        PackageTests.testOverlays2
    ]

    let filename = __FILE__
    
    static func testBasic() throws {
        let path = "./tests/collateral/basic.atpkg"
        let package = try Package(path: path)
        
        try test.assert(package.name == "basic")
        try test.assert(package.version == "0.1.0-dev")
        
        try test.assert(package.tasks.count == 1)
        guard let task = package.tasks["build"] else { try test.assert(false); return }
        try test.assert(task["tool"]?.string == "lldb-build")
        try test.assert(task["name"]?.string == "json-swift")
        try test.assert(task["output-type"]?.string == "lib")
        try test.assert(task["source"]?.array?.count == 2)
        try test.assert(task["source"]?.array?[0].string == "src/**.swift")
        try test.assert(task["source"]?.array?[1].string == "lib/**.swift")
    }

    static func testImport() throws {
        let path = "./tests/collateral/import-src.atpkg"
        let package = try Package(path: path)
        
        try test.assert(package.name == "import_src")
        try test.assert(package.importedPackages.count == 1)
        try test.assert(package.importedPackages[0].name == "import_dst")
        try test.assert(package.importedPackages[0].importedPackages.count == 1)
        try test.assert(package.importedPackages[0].importedPackages[0].name == "basic")
        
        try test.assert(package.tasks["import_dst/build"]?["name"]?.string == "json-swift")
        try test.assert(package.tasks["basic/build"]?["name"]?.string == "json-swift")
    }

    static func testOverlays() throws {
        let path = "./tests/collateral/overlays-src.atpkg"
        let package = try Package(path: path)

        guard let build = package.tasks["build"] else { try test.assert(false); return }
        let config = try build.mergedConfig()
        
        try test.assert(config["compile-options"]?.array?.count == 4)
        try test.assert(config["compile-options"]?.array?[0].string == "--task-compile-options")
        try test.assert(config["compile-options"]?.array?[1].string == "--macosx-task")
        try test.assert(config["compile-options"]?.array?[2].string == "--macosx-overlays-dst")
        try test.assert(config["compile-options"]?.array?[3].string == "--macosx-overlays-src")
        try test.assert(config["something"]?.string == "new")
    }


    static func testOverlays2() throws {
        let filepath = "./tests/collateral/overlays.atpkg"
        let package = try Package(path: filepath, overrides: [:])
        guard let compileOptions = try package.tasks["build"]?.mergedConfig()["compile-options"]?.array else {
            fatalError("No compile options?")
        }
        try test.assert(compileOptions.count == 2)
        try test.assert(compileOptions[0].string == "-D")
        try test.assert(compileOptions[1].string == "AWESOME")

        let package2 = try Package(path: filepath, overlays: ["more-awesome"]) 
        guard let compileOptions2 = try package2.tasks["build"]?.mergedConfig()["compile-options"]?.array else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions2.count == 4)
        try test.assert(compileOptions2[0].string == "-D")
        try test.assert(compileOptions2[1].string == "AWESOME")
        try test.assert(compileOptions2[2].string == "-D")
        try test.assert(compileOptions2[3].string == "MORE_AWESOME")

        let package3 = try Package(path: filepath, overlays: ["most-taskspecific"])
        guard let compileOptions3 = try package3.tasks["build"]?.mergedConfig()["compile-options"]?.array else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions3.count == 4)
        try test.assert(compileOptions3[0].string == "-D")
        try test.assert(compileOptions3[1].string == "AWESOME")
        try test.assert(compileOptions3[2].string == "-D")
        try test.assert(compileOptions3[3].string == "MOST_AWESOME")

        let package4 = try Package(path: filepath, overlays: ["most-taskspecific-two"])
        guard let compileOptions4 = try package4.tasks["build"]?.mergedConfig()["compile-options"]?.array else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions4.count == 4)
        try test.assert(compileOptions4[0].string == "-D")
        try test.assert(compileOptions4[1].string == "AWESOME")
        try test.assert(compileOptions4[2].string == "-D")
        try test.assert(compileOptions4[3].string == "MOST_AWESOME")

        let package5 = try Package(path: filepath, overlays: ["stringOption"]) 
        guard let stringOption = try package5.tasks["build"]?.mergedConfig()["stringOption"]?.string else {
            fatalError("no string option?")
        }
        try test.assert(stringOption == "stringOption")

        let package6 = try Package(path: filepath, overlays: ["emptyVecOption"]) 
        guard let vecOption = try package6.tasks["build"]?.mergedConfig()["emptyVecOption"]?.array else {
            fatalError("no vec option?")
        }
        try test.assert(vecOption.count == 1)

        try test.assert(vecOption[0].string == "OVERLAY")

        let package7 = try Package(path: filepath, overlays: ["boolOption"])
        guard let boolOption = try package7.tasks["build"]?.mergedConfig()["boolOption"]?.bool else {
            fatalError("no bool option?")
        }
        try test.assert(boolOption == true)
    }

}
