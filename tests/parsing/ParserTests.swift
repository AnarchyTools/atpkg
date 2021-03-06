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


import atfoundation
import atpkg

class ParserTests: Test {
    required init() {}
    let tests = [
        ParserTests.testBasic,
        ParserTests.testEscape
    ]

    let filename = #file

    static func testBasic() throws {
        let filepath = Path("tests/collateral/basic.atpkg")
        guard let parser = try Parser(filepath: filepath) else {
            try test.assert(false); return
        }

        let result = try parser.parse()

        let name = result.properties["name"]
        try test.assert(name != nil)
        try test.assert(name?.string == "basic")

        let version = result.properties["version"]
        try test.assert(version != nil)
        try test.assert(version?.string == "0.1.0-dev")

        let tasks = result.properties["tasks"]
        try test.assert(tasks != nil)

        let build = tasks?.map?["build"]
        try test.assert(build != nil)

        let tool = build?.map?["tool"]
        try test.assert(tool != nil)
        try test.assert(tool?.string == "lldb-build")

        let buildName = build?.map?["name"]
        try test.assert(buildName != nil)
        try test.assert(buildName?.string == "json-swift")

        let outputType = build?.map?["output-type"]
        try test.assert(outputType != nil)
        try test.assert(outputType?.string == "lib")

        let source = build?.map?["sources"]
        try test.assert(source != nil)
        try test.assert(source?.vector != nil)
        try test.assert(source?.vector?[0].string == "src/**.swift")
        try test.assert(source?.vector?[1].string == "lib/**.swift")
    }
    
    static func testEscape() throws {
        let filepath = Path("tests/collateral/escape.atpkg")
        guard let parser = try Parser(filepath: filepath) else {
            try test.assert(false); return
        }

        let result = try parser.parse()

        let name = result.properties["name"]
        try test.assert(name != nil)
        try test.assert(name?.string == "basic")

        let version = result.properties["version"]
        try test.assert(version != nil)
        try test.assert(version?.string == "0.1.0-dev")

        let tasks = result.properties["tasks"]
        try test.assert(tasks != nil)

        let build = tasks?.map?["build"]
        try test.assert(build != nil)

        let tool = build?.map?["tool"]
        try test.assert(tool != nil)
        try test.assert(tool?.string == "lldb-build")

        let buildName = build?.map?["name"]
        try test.assert(buildName != nil)
        try test.assert(buildName?.string == "json-swift")
        
        let description = build?.map?["description"]
        try test.assert(description != nil)
        try test.assert(description?.string == "This the \"the\" most important thing.\n\tDon\'t you think so?")

        let outputType = build?.map?["output-type"]
        try test.assert(outputType != nil)
        try test.assert(outputType?.string == "lib")

        let source = build?.map?["sources"]
        try test.assert(source != nil)
        try test.assert(source?.vector != nil)
        try test.assert(source?.vector?[0].string == "src/**.swift")
        try test.assert(source?.vector?[1].string == "lib/**.swift")
    }
}