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

func outputBaseline(scanner: Scanner) {
    print("--- baseline ---")
    while let info = scanner.next() {
        guard let c = info.character else { fatalError("scanner is broken!") }
        var str = String(c)

        switch str {
        case "\n": str = "\\n"
        case "\t": str = "\\t"
        case "\r": str = "\\r"
        case "\"": str = "\\\""
        default: break
        }
        
        print("try test.assert(scanner.next()?.character == \"\(str)\")")
    }
    print("--- end baseline ---")
}

class ScannerTests: Test {
    required init() {}
    let tests = [
        ScannerTests.testBasicClj
    ]

    let filename = __FILE__

    static func testBasicClj() throws {
        let filepath = "./tests/collateral/basic.atpkg"
        
        let content: String = try NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding).toString
        let scanner = Scanner(content: content)
        
        try test.assert(scanner.next()?.character == ";")
        try test.assert(scanner.next()?.character == ";")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "T")
        try test.assert(scanner.next()?.character == "h")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "h")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "m")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "c")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "m")
        try test.assert(scanner.next()?.character == "p")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == ".")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == "(")
        try test.assert(scanner.next()?.character == "p")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "c")
        try test.assert(scanner.next()?.character == "k")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "g")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "n")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "m")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "c")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "v")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == "r")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "0")
        try test.assert(scanner.next()?.character == ".")
        try test.assert(scanner.next()?.character == "1")
        try test.assert(scanner.next()?.character == ".")
        try test.assert(scanner.next()?.character == "0")
        try test.assert(scanner.next()?.character == "-")
        try test.assert(scanner.next()?.character == "d")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == "v")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "k")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "{")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "u")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "d")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "{")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "d")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "-")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "u")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "d")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "n")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "m")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "j")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "n")
        try test.assert(scanner.next()?.character == "-")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "w")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "u")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "p")
        try test.assert(scanner.next()?.character == "u")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "-")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "y")
        try test.assert(scanner.next()?.character == "p")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == ":")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "u")
        try test.assert(scanner.next()?.character == "r")
        try test.assert(scanner.next()?.character == "c")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "[")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "r")
        try test.assert(scanner.next()?.character == "c")
        try test.assert(scanner.next()?.character == "/")
        try test.assert(scanner.next()?.character == "*")
        try test.assert(scanner.next()?.character == "*")
        try test.assert(scanner.next()?.character == ".")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "w")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "b")
        try test.assert(scanner.next()?.character == "/")
        try test.assert(scanner.next()?.character == "*")
        try test.assert(scanner.next()?.character == "*")
        try test.assert(scanner.next()?.character == ".")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "w")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "\"")
        try test.assert(scanner.next()?.character == "]")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "}")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "}")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == ")")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == "\n")
        try test.assert(scanner.next()?.character == ";")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "E")
        try test.assert(scanner.next()?.character == "n")
        try test.assert(scanner.next()?.character == "d")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "o")
        try test.assert(scanner.next()?.character == "f")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "t")
        try test.assert(scanner.next()?.character == "h")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == "a")
        try test.assert(scanner.next()?.character == "m")
        try test.assert(scanner.next()?.character == "p")
        try test.assert(scanner.next()?.character == "l")
        try test.assert(scanner.next()?.character == "e")
        try test.assert(scanner.next()?.character == ".")
    }
}