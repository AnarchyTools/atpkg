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
import atpkg

class PackageTests: Test {
    required init() {}
    let tests = [
        PackageTests.testBasic,
        PackageTests.testImport,
        // PackageTests.testMergeConfigs,
        // PackageTests.testInvalidMergeConfigs,
        PackageTests.testOverlays
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
}
