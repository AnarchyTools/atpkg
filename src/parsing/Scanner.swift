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

public struct ScannerInfo {
    public let character: Character?
    public let line: Int
    public let column: Int
}

final public class Scanner {

    var content: String
    var index: String.Index
    var current: ScannerInfo? = nil

    private var shouldStall = false

    var line: Int = 1
    var column: Int = 1

    public init(content: String) {
        self.content = content
        self.index = content.startIndex
        self._defaults()
    }

    func _defaults() {
        self.index = content.startIndex
        self.line = 1
        self.column = 1
        self.shouldStall = false
        self.current = nil
   }

    public func stall() {
        shouldStall = true
    }

    public func next() -> ScannerInfo? {
        if shouldStall {
            shouldStall = false
            return current
        }

        if index == content.endIndex {
            current = nil
        }
        else {
            current = ScannerInfo(character: content[index], line: line, column: column)
            index = content.index(after: index)

            if current?.character == "\n" {
                line += 1
                column = 1
            }
            else {
                column += 1
            }
        }

        return current
    }

    public func peek() -> ScannerInfo? {
        return current
    }
}