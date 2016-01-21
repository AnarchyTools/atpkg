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

public enum ParseError: ErrorType {
    case InvalidPackageFile
    case ExpectedTokenType(TokenType, Token?)
    case InvalidTokenForValueType(Token?)
}

final public class Parser {
    let lexer: Lexer
    
    private func next() -> Token? {
        while true {
            guard let token = lexer.next() else { return nil }
            if token.type != .Comment && token.type != .Terminal {
                return lexer.peek()
            }
        }
    }
    
    public init?(filepath: String) {
        guard let content = try? NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        
        let scanner = Scanner(content: content.toString)
        self.lexer = Lexer(scanner: scanner)
    }
    
    public func parse() throws -> DeclarationType {
        guard let token = next() else { throw ParseError.InvalidPackageFile }
        
        if token.type == .OpenParen {
            return try parseDeclaration()
        }
        else {
            throw ParseError.ExpectedTokenType(.OpenParen, token)
        }
    }
    
    private func parseDeclaration() throws -> DeclarationType {
        let decl = DeclarationType()
        decl.name = try parseIdentifier()
        
        decl.properties = try parseKeyValuePairs()
        return decl
    }
    
    private func parseKeyValuePairs() throws -> [String:Value] {
        var pairs: [String:Value] = [:]

        while let token = next() where token.type != .CloseParen && token.type != .CloseBrace {
            lexer.stall()
            
            let key = try parseKey()
            let value = try parseValue()
            
            pairs[key] = value
        }
        lexer.stall()

        return pairs
    }
    
    private func parseKey() throws -> String {
        let colon = next()
        if colon?.type != .Colon { throw ParseError.ExpectedTokenType(.Colon, lexer.peek()) }
        
        return try parseIdentifier()
    }
    
    private func parseIdentifier() throws -> String {
        guard let identifier = next() else { throw ParseError.ExpectedTokenType(.Identifier, lexer.peek()) }
        if identifier.type != .Identifier { throw ParseError.ExpectedTokenType(.Identifier, lexer.peek()) }
        
        return identifier.value
    }
    
    private func parseValue() throws -> Value {
        guard let token = next() else { throw ParseError.InvalidTokenForValueType(nil) }
        
        switch token.type {
        case .OpenBrace: lexer.stall(); return try parseMap()
        case .OpenBracket: lexer.stall(); return try parseVector()
        case .StringLiteral: return .StringLiteral(token.value)
        case .Identifier where token.value == "true": return .BoolLiteral(true)
        case .Identifier where token.value == "false": return .BoolLiteral(false)
        default: throw ParseError.InvalidTokenForValueType(token)
        }
    }
    
    private func parseVector() throws -> Value {
        if let token = next() where token.type != .OpenBracket { throw ParseError.ExpectedTokenType(.OpenBracket, token) }
        var items: [Value] = []
        
        while let token = next() where token.type != .CloseBracket {
            lexer.stall()
            items.append(try parseValue())
        }
        lexer.stall()

        if let token = next() where token.type != .CloseBracket { throw ParseError.ExpectedTokenType(.CloseBracket, token) }

        return .Vector(items)
    }
    
    private func parseMap() throws -> Value {
        if let token = next() where token.type != .OpenBrace { throw ParseError.ExpectedTokenType(.OpenBrace, token) }
        let items = try parseKeyValuePairs()
        if let token = next() where token.type != .CloseBrace { throw ParseError.ExpectedTokenType(.CloseBrace, token) }
        
        return .Map(items)
    }
}
