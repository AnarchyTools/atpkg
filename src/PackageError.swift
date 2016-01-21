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

/**
 * A custom error type to provide contextual error information to outside
 * callers of the `AnarchyPackage` API.
 */
public struct PackageError: ErrorType {
    /*
     * Implementation Note:
     * ---------------------
     * Ok... why not just use an associated enum? Well, that would be nice.
     * However, there is no way to specify defaults for values. So we can
     * not use `__LINE__` very easily in this context. This means that we
     * need to actually create `init()`-like functions for the enums. Yeah,
     * it's that awesome. This is the least amount of code way to solve this
     * problem that I know of.
     *
     * Is it ideal, no.
     */
    
    public enum ErrorType {
        case InvalidDataType(Value, String)
        case InvalidDeclarationType(String)
        case InvalidPackageFilePath(String)
    }
    
    /** The specific type of error. */
    let type: PackageError.ErrorType
    
    /** The line number, in the source file, of the error. */
    let line: Int
    
    /** The column number, in the source file, of the error. */
    let column: Int

    /** Tne name of the file for the originating error. */
    let fileName: String
    
    /** The name of the function that originating error was invoked from. */
    let functionName: String
    
    public init(
        _ type: PackageError.ErrorType,
        line: Int = __LINE__,
        column: Int = __COLUMN__,
        fileName: String = __FILE__,
        functionName: String = __FUNCTION__)
    {
        self.type = type
        self.line = line
        self.column = column
        self.fileName = fileName
        self.functionName = functionName
    }
}
