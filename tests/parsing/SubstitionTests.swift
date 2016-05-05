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

class SubstitutionTests: Test {
    required init() {}
    let tests = [
        SubstitutionTests.testBasic,
        SubstitutionTests.testCollectSources,
        SubstitutionTests.testEscapedValue
    ]

    let filename = #file

    static func testBasic() throws {
        let filepath = Path("tests/collateral/basic.atpkg")
        let package = try Package(filepath: filepath, overlay: [], focusOnTask: nil)
        try test.assert(evaluateSubstitutions(input: "${test_substitution}", package: package) == "test_substitution")
        try test.assert(evaluateSubstitutions(input: "foobly-doobly-doo ${test_substitution} doobly-doo", package: package) == "foobly-doobly-doo test_substitution doobly-doo")
        try test.assert(evaluateSubstitutions(input: "foobly-doobly-doo \\${test_substitution} doobly-doo", package: package) == "foobly-doobly-doo ${test_substitution} doobly-doo")
    }

    static func testCollectSources() throws {
        let filepath = Path("tests/collateral/collect_sources/build.atpkg")
        let package = try Package(filepath: filepath, overlay: [], focusOnTask: nil)
        try test.assert(evaluateSubstitutions(input: "${collect_sources:default}", package: package) == "tests/collateral/collect_sources/src/a.swift tests/collateral/collect_sources/src/b.swift")
    }

    static func testEscapedValue() throws {
        let filepath = Path("tests/collateral/escape.atpkg")
        let package = try Package(filepath: filepath, overlay: [], focusOnTask: nil)
        try test.assert(evaluateSubstitutions(input: "\\${ATBUILD_USER_PATH}", package: package) == "${ATBUILD_USER_PATH}")
    }
}