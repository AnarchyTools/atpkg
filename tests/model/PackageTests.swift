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
        PackageTests.testMergeConfigs,
        PackageTests.testOverlays,
        PackageTests.testExportedOverlays
    ]

    let filename = __FILE__
    
    static func testBasic() throws {
        let path = "./tests/collateral/basic.atpkg"
        let package = try Package(path: path)
        
        try test.assert(package.name == "basic")
        try test.assert(package.version == "0.1.0-dev")
        
        try test.assert(package.tasks?.count == 1)
        guard let task = package.tasks?["build"]?.dictionary else { try test.assert(false); return }
        try test.assert(task["tool"]?.string == "lldb-build")
        try test.assert(task["name"]?.string == "json-swift")
        try test.assert(task["output-type"]?.string == "lib")
        try test.assert(task["source"]?.array?.count == 2)
        try test.assert(task["source"]?.array?[0].string == "src/**.swift")
        try test.assert(task["source"]?.array?[1].string == "lib/**.swift")
    }

    static func testImport() throws {
        let path = "./tests/collateral/import_src.atpkg"
        let package = try Package(path: path)
        
        try test.assert(package.name == "import_src")
        try test.assert(package.importedPackages.count == 1)
        try test.assert(package.importedPackages[0].name == "import_dst")
        try test.assert(package.importedPackages[0].importedPackages.count == 1)
        try test.assert(package.importedPackages[0].importedPackages[0].name == "basic")
    }
    
    static func testMergeConfigs() throws {
        let map1: ConfigMap = [
            "array" : Value.ArrayLiteral([.StringLiteral("happy"), .StringLiteral("days")]),
            "map" : Value.DictionaryLiteral([
                "key": .StringLiteral("value"),
                "nested": Value.DictionaryLiteral(["ok": .BoolLiteral(true)])]),
            "string": .StringLiteral("string-value"),
            "integer": .IntegerLiteral(1234),
            "float": .FloatLiteral(1.234),
            "bool": .BoolLiteral(false)
        ]

        let map2: ConfigMap = [
            "array" : Value.ArrayLiteral([.StringLiteral("oh")]),
            "map" : Value.DictionaryLiteral([
                "value": .StringLiteral("pair"),
                "nested": Value.DictionaryLiteral(["ok": .BoolLiteral(false)])])
        ]

        let merged = mergeConfigs([map1, map2])
        try test.assert(merged["array"]?.array?[0].string == "happy")
        try test.assert(merged["array"]?.array?[1].string == "days")
        try test.assert(merged["array"]?.array?[2].string == "oh")
        try test.assert(merged["map"]?.dictionary?["nested"]?.dictionary?["ok"]?.bool == false)
        try test.assert(merged["map"]?.dictionary?["key"]?.string == "value")
        try test.assert(merged["map"]?.dictionary?["value"]?.string == "pair")
        try test.assert(merged["bool"]?.bool == false)
        try test.assert(merged["integer"]?.integer == 1234)
    }

    static func testOverlays() throws {
        // let filepath = "./tests/collateral/overlays.atpkg"
        // guard let package = Package(filepath: filepath, overlay: []) else { print("error"); try test.assert(false); return }
        // guard let compileOptions = package.tasks["build"]?["compile-options"]?.vector else {
        //     fatalError("No compile options?")
        // }
        // try test.assert(compileOptions.count == 2)
        // try test.assert(compileOptions[0].string == "-D")
        // try test.assert(compileOptions[1].string == "AWESOME")

        // guard let package2 = Package(filepath: filepath, overlay: ["more-awesome"]) else { print("error"); try test.assert(false); return }
        // guard let compileOptions2 = package2.tasks["build"]?["compile-options"]?.vector else {
        //     fatalError("no compile options?")
        // }
        // try test.assert(compileOptions2.count == 4)
        // try test.assert(compileOptions2[0].string == "-D")
        // try test.assert(compileOptions2[1].string == "AWESOME")
        // try test.assert(compileOptions2[2].string == "-D")
        // try test.assert(compileOptions2[3].string == "MORE_AWESOME")

        // guard let package3 = Package(filepath: filepath, overlay: ["most-taskspecific"]) else { print("error"); try test.assert(false); return }
        // guard let compileOptions3 = package3.tasks["build"]?["compile-options"]?.vector else {
        //     fatalError("no compile options?")
        // }
        // try test.assert(compileOptions3.count == 4)
        // try test.assert(compileOptions3[0].string == "-D")
        // try test.assert(compileOptions3[1].string == "AWESOME")
        // try test.assert(compileOptions3[2].string == "-D")
        // try test.assert(compileOptions3[3].string == "MOST_AWESOME")

        // guard let package4 = Package(filepath: filepath, overlay: ["most-taskspecific-two"]) else { print("error"); try test.assert(false); return }
        // guard let compileOptions4 = package4.tasks["build"]?["compile-options"]?.vector else {
        //     fatalError("no compile options?")
        // }
        // try test.assert(compileOptions4.count == 4)
        // try test.assert(compileOptions4[0].string == "-D")
        // try test.assert(compileOptions4[1].string == "AWESOME")
        // try test.assert(compileOptions4[2].string == "-D")
        // try test.assert(compileOptions4[3].string == "MOST_AWESOME")

        // guard let package5 = Package(filepath: filepath, overlay: ["string-option"]) else { print("error"); try test.assert(false); return }
        // guard let stringOption = package5.tasks["build"]?["string-option"]?.string else {
        //     fatalError("no string option?")
        // }
        // try test.assert(stringOption == "stringOption")

        // guard let package6 = Package(filepath: filepath, overlay: ["empty-vec-option"]) else { print("error"); try test.assert(false); return }
        // guard let vecOption = package6.tasks["build"]?["empty-vec-option"]?.vector else {
        //     fatalError("no vec option?")
        // }
        // try test.assert(vecOption.count == 1)

        // try test.assert(vecOption[0].string == "OVERLAY")

        // guard let package7 = Package(filepath: filepath, overlay: ["bool-option"]) else { print("error"); try test.assert(false); return }
        // guard let boolOption = package7.tasks["build"]?["bool-option"]?.bool else {
        //     fatalError("no bool option?")
        // }
        // try test.assert(boolOption == true)
    }

    static func testExportedOverlays() throws {
        // let filepath = "./tests/collateral/overlays_src.atpkg"

        // guard let package2 = Package(filepath: filepath, overlay: []) else { print("error"); try test.assert(false); return }
        // guard let compileOptions2 = package2.tasks["build"]?["compile-options"]?.vector else {
        //     fatalError("no compile options?")
        // }
        // try test.assert(compileOptions2.count == 6)
        // try test.assert(compileOptions2[0].string == "-D")
        // try test.assert(compileOptions2[1].string == "AWESOME")
        // try test.assert(compileOptions2[2].string == "-D")
        // try test.assert(compileOptions2[3].string == "MORE_AWESOME")
        // try test.assert(compileOptions2[4].string == "-D")
        // try test.assert(compileOptions2[5].string == "MOST_AWESOME")
    }
}
