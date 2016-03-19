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

func outputBaseline(lexer: Lexer) {
    print("--- baseline ---")
    while let token = lexer.next() {
        let type = String(reflecting: token.type).replacingOccurrences(of: "atpkgparser.", with: "")
        var value = ""
        
        switch token.type {
        case .Terminal: value = "\\n"
        default: value = token.value
        }
        
        let output = "try test.assert(lexer.next() == Token(type: \(type), value: \"\(value)\", line: \(token.line), column: \(token.column)))"
        print(output)
    }
    print("--- end baseline ---")
}
    
class LexerTests: Test {
    required init() {}
    let tests = [
        LexerTests.testBasic
    ]

    let filename = #file
        
    static func testBasic() throws {
        let filepath = "./tests/collateral/basic.atpkg"

        let content: String = try NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding).toString
        let scanner = Scanner(content: content)
        let lexer = Lexer(scanner: scanner)
        
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Comment, value: " This is the most basic of sample files.", line: 1, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 2, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenParen, value: "(", line: 3, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "package", line: 3, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 3, column: 9))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 4, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "name", line: 4, column: 4))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "basic", line: 4, column: 9))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 4, column: 16))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 5, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "version", line: 5, column: 4))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "0.1.0-dev", line: 5, column: 12))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 5, column: 23))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 6, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 7, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "tasks", line: 7, column: 4))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBrace, value: "{", line: 7, column: 10))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 7, column: 11))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 8, column: 5))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "build", line: 8, column: 6))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBrace, value: "{", line: 8, column: 12))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 8, column: 13))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 9, column: 7))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "tool", line: 9, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lldb-build", line: 9, column: 13))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 9, column: 25))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 10, column: 7))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "name", line: 10, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "json-swift", line: 10, column: 13))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 10, column: 25))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 11, column: 7))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "output-type", line: 11, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lib", line: 11, column: 20))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 11, column: 26))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 12, column: 7))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "sources", line: 12, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBracket, value: "[", line: 12, column: 16))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "src/**.swift", line: 12, column: 17))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lib/**.swift", line: 12, column: 32))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBracket, value: "]", line: 12, column: 46))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 12, column: 47))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBrace, value: "}", line: 13, column: 5))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 13, column: 6))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBrace, value: "}", line: 14, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 14, column: 4))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseParen, value: ")", line: 15, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 15, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 16, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Comment, value: " End of the sample.", line: 17, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.EOF, value: "", line: 0, column: 0))
    }
}