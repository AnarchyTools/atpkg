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

// NOTE: This is the crappiest test thing ever... but it works for now.
import atfoundation


extension String : ErrorProtocol {}

enum test {
    static func assert(_ condition: Bool, file: String = #file, functionName: String = #function, line: Int = #line) throws {
        if !condition {
            print(" \(file):\(line) \(functionName)  **FAILED**")
            throw "atpkg.tests.failed"
        }
    }
}

protocol Test {
    init()
    func runTests() -> Bool
    
    var tests: [() throws -> ()] { get }
    var filename: String { get }
}

extension Test {
    func runTests() -> Bool {
        print("Tests for \(filename)")
        var passed = true
        for test in tests {
            do {
                try test()
            }
            catch {
                print("\(filename): **FAILED** \(error)")
                passed = false
            }
        }
        return passed
    }
}


let tests: [Test] = [
    // NOTE: Add your test classes here...
    SubstitutionTests(),
    ScannerTests(),
    LexerTests(),
    ParserTests(),
    PackageTests()
]

var passed = true
for test in tests {
    passed = passed && test.runTests()
}

if !passed { exit(1) }