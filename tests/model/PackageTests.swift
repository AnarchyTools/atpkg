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
        PackageTests.testOverlays,
        PackageTests.testExportedOverlays,
        PackageTests.testChainedImports,
        PackageTests.testImportPaths,
        PackageTests.testChainedImportOverlays,
        PackageTests.nonVectorImport
    ]

    let filename = __FILE__
    
    static func testBasic() throws {
        let filepath = "./tests/collateral/basic.atpkg"

        guard let parser = Parser(filepath: filepath) else {
            try test.assert(false); return
        }
        
        let result = try parser.parse()
        let package = try Package(type: result, overlay: [], pathOnDisk: "./tests/collateral")
        
        try test.assert(package.name == "basic")
        try test.assert(package.version == "0.1.0-dev")
        try test.assert(package.tasks.count == 2) //indexed twice, by qualified and unqualified name
        for (key, task) in package.tasks {
            try test.assert(key == "build" || key == "basic.build")
            try test.assert(task.tool == "lldb-build")
            try test.assert(task["name"]?.string == "json-swift")
            try test.assert(task["output-type"]?.string == "lib")
            try test.assert(task["sources"]?.vector?.count == 2)
            try test.assert(task["sources"]?.vector?[0].string == "src/**.swift")
            try test.assert(task["sources"]?.vector?[1].string == "lib/**.swift")
        }
    }

    static func testImport() throws {
        let filepath = "./tests/collateral/import_src.atpkg"
        let package = try Package(filepath: filepath, overlay: [])

        try test.assert(package.tasks["import_dst.build"] != nil)
        try test.assert(package.tasks["import_dst.build"]!.importedPath == "./tests/collateral/")
    }

    static func testOverlays() throws {
        let filepath = "./tests/collateral/overlays.atpkg"
        let package = try Package(filepath: filepath, overlay: [])
        guard let compileOptions = package.tasks["build"]?["compile-options"]?.vector else {
            fatalError("No compile options?")
        }
        try test.assert(compileOptions.count == 2)
        try test.assert(compileOptions[0].string == "-D")
        try test.assert(compileOptions[1].string == "AWESOME")

        let package2 = try Package(filepath: filepath, overlay: ["more-awesome"])
        guard let compileOptions2 = package2.tasks["build"]?["compile-options"]?.vector else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions2.count == 4)
        try test.assert(compileOptions2[0].string == "-D")
        try test.assert(compileOptions2[1].string == "AWESOME")
        try test.assert(compileOptions2[2].string == "-D")
        try test.assert(compileOptions2[3].string == "MORE_AWESOME")

        let package3 = try Package(filepath: filepath, overlay: ["most-taskspecific"])
        guard let compileOptions3 = package3.tasks["build"]?["compile-options"]?.vector else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions3.count == 4)
        try test.assert(compileOptions3[0].string == "-D")
        try test.assert(compileOptions3[1].string == "AWESOME")
        try test.assert(compileOptions3[2].string == "-D")
        try test.assert(compileOptions3[3].string == "MOST_AWESOME")

        let package4 = try Package(filepath: filepath, overlay: ["most-taskspecific-two"])
        guard let compileOptions4 = package4.tasks["build"]?["compile-options"]?.vector else {
            fatalError("no compile options?")
        }
        try test.assert(compileOptions4.count == 4)
        try test.assert(compileOptions4[0].string == "-D")
        try test.assert(compileOptions4[1].string == "AWESOME")
        try test.assert(compileOptions4[2].string == "-D")
        try test.assert(compileOptions4[3].string == "MOST_AWESOME")

        let package5 = try Package(filepath: filepath, overlay: ["string-option"])
        guard let stringOption = package5.tasks["build"]?["string-option"]?.string else {
            fatalError("no string option?")
        }
        try test.assert(stringOption == "stringOption")

        let package6 = try Package(filepath: filepath, overlay: ["empty-vec-option"])
        guard let vecOption = package6.tasks["build"]?["empty-vec-option"]?.vector else {
            fatalError("no vec option?")
        }
        try test.assert(vecOption.count == 1)

        try test.assert(vecOption[0].string == "OVERLAY")

        let package7 = try Package(filepath: filepath, overlay: ["bool-option"])
        guard let boolOption = package7.tasks["build"]?["bool-option"]?.bool else {
            fatalError("no bool option?")
        }
        try test.assert(boolOption == true)
    }

    static func testExportedOverlays() throws {
        let filepath = "./tests/collateral/overlays_src.atpkg"

        let package2 = try Package(filepath: filepath, overlay: [])
        guard let compileOptions2 = package2.tasks["build"]?["compile-options"]?.vector else {
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

    static func testChainedImports () throws {
        let filepath = "./tests/collateral/chained_imports/a.atpkg"
        let package = try Package(filepath: filepath, overlay: [])
        guard let a_default_unqualified = package.tasks["default"] else {
            fatalError("No default task")
        }
        try test.assert(a_default_unqualified["name"]?.string == "a_default")

        guard let a_default_qualified = package.tasks["a.default"] else {
            fatalError("No default task (qualified)")
        }
        try test.assert(a_default_qualified["name"]?.string == "a_default")

        guard let b_default_qualified = package.tasks["b.default"] else {
            fatalError("No default task in b")
        }
        try test.assert(b_default_qualified["name"]?.string == "b_default")

        guard let c_default_qualified = package.tasks["c.default"] else {
            fatalError("No default task in c")
        }
        try test.assert(c_default_qualified["name"]?.string == "c_default")

        //check package dependency graph
        let _ = package.prunedDependencyGraph(a_default_unqualified)
        
    }

    static func testImportPaths () throws {
        let filepath = "./tests/collateral/import_paths/a.atpkg"
        let package = try Package(filepath: filepath, overlay: [])
        guard let a_default_unqualified = package.tasks["default"] else {
            fatalError("No default task")
        }
        try test.assert(a_default_unqualified["name"]?.string == "a_default")

        guard let a_default_qualified = package.tasks["a.default"] else {
            fatalError("No default task (qualified)")
        }
        try test.assert(a_default_qualified["name"]?.string == "a_default")

        guard let b_default_qualified = package.tasks["b.default"] else {
            fatalError("No default task in b")
        }
        try test.assert(b_default_qualified["name"]?.string == "b_default")

        guard let c_default_qualified = package.tasks["c.default"] else {
            fatalError("No default task in c")
        }
        try test.assert(c_default_qualified["name"]?.string == "c_default")

        //check package dependency graph
        let _ = package.prunedDependencyGraph(a_default_unqualified)

        //check each import path
        try test.assert(a_default_unqualified.importedPath == "./tests/collateral/import_paths/")
        try test.assert(a_default_qualified.importedPath == "./tests/collateral/import_paths/")
        try test.assert(b_default_qualified.importedPath == "./tests/collateral/import_paths/b/")
        try test.assert(c_default_qualified.importedPath == "./tests/collateral/import_paths/b/c/")
    }

    static func testChainedImportOverlays() throws {
        let filepath = "./tests/collateral/chained_import_overlays/a.atpkg"
        let package = try Package(filepath: filepath, overlay: ["b.foo"])
        guard let a_qualified = package.tasks["a.default"] else { print("error"); try test.assert(false); return }
        guard let options = a_qualified["compile-options"]?.vector else {
            fatalError("Invalid options vector")
        }
        try test.assert(options.count == 1)
        for opt in options {
            guard let str = opt.string else { fatalError("Non-string opt \(opt)")}
            try test.assert(str == "foo")
        }
    }

    static func nonVectorImport() throws {
        let filepath = "./tests/collateral/non_vector_import.atpkg"
        if let _ = try? Package(filepath: filepath, overlay: []) {
            try test.assert(false) //no diagnostic
        }
    }
}
