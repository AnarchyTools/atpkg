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
        PackageTests.testMixins,
        PackageTests.testExportedMixins
    ]

    let filename = __FILE__
    
    static func testBasic() throws {
        let filepath = "./tests/collateral/basic.atpkg"

        guard let parser = Parser(filepath: filepath) else {
            try test.assert(false); return
        }
        
        let result = try parser.parse()
        guard let package = Package(type: result, configurations: [:], pathOnDisk: "./tests/collateral") else { try test.assert(false); return }
        
        try test.assert(package.name == "basic")
        try test.assert(package.version == "0.1.0-dev")
        
        try test.assert(package.tasks.count == 1)
        for (key, task) in package.tasks {
            try test.assert(key == "build")
            try test.assert(task.tool == "lldb-build")
            try test.assert(task["name"]?.string == "json-swift")
            try test.assert(task["output-type"]?.string == "lib")
            try test.assert(task["source"]?.vector?.count == 2)
            try test.assert(task["source"]?.vector?[0].string == "src/**.swift")
            try test.assert(task["source"]?.vector?[1].string == "lib/**.swift")
        }
    }

    static func testImport() throws {
        let filepath = "./tests/collateral/import_src.atpkg"
        guard let package = Package(filepath: filepath, configurations: [:]) else { print("error"); try test.assert(false); return }

        try test.assert(package.tasks["import_dst.build"] != nil)
        try test.assert(package.tasks["import_dst.build"]!.importedPath == "./tests/collateral/")
    }

    static func testMixins() throws {
        let filepath = "./tests/collateral/mixins.atpkg"
        guard let package = Package(filepath: filepath, configurations: [:]) else { print("error"); try test.assert(false); return }
        guard let compileOptions = package.tasks["build"]?["compileOptions"]?.vector else {
            fatalError("No compile options?")
        }
        try test.assert(compileOptions.count == 4)
        try test.assert(compileOptions[0].string == "-D")
        try test.assert(compileOptions[1].string == "AWESOME")
        try test.assert(compileOptions[2].string == "-D")
        try test.assert(compileOptions[3].string == "MORE_AWESOME")

        guard let package2 = Package(filepath: filepath, configurations: ["awesome":"most"]) else { print("error"); try test.assert(false); return }
        guard let compileOptions2 = package2.tasks["build"]?["compileOptions"]?.vector else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions2.count == 6)
        try test.assert(compileOptions2[0].string == "-D")
        try test.assert(compileOptions2[1].string == "AWESOME")
        try test.assert(compileOptions2[2].string == "-D")
        try test.assert(compileOptions2[3].string == "MORE_AWESOME")
        try test.assert(compileOptions2[4].string == "-D")
        try test.assert(compileOptions2[5].string == "MOST_AWESOME")

    }

    static func testExportedMixins() throws {
        let filepath = "./tests/collateral/mixins_src.atpkg"

        guard let package2 = Package(filepath: filepath, configurations: [:]) else { print("error"); try test.assert(false); return }
        guard let compileOptions2 = package2.tasks["build"]?["compileOptions"]?.vector else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions2.count == 6)
        try test.assert(compileOptions2[0].string == "-D")
        try test.assert(compileOptions2[1].string == "AWESOME")
        try test.assert(compileOptions2[2].string == "-D")
        try test.assert(compileOptions2[3].string == "MORE_AWESOME")
        try test.assert(compileOptions2[4].string == "-D")
        try test.assert(compileOptions2[5].string == "MOST_AWESOME")

    }
}
