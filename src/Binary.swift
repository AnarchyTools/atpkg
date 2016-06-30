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

///A "channel" of releases, such as `stable`, `linux`, `osx-framework`, `swift3`, etc.
public struct BinaryChannel {
    public let name: String
    public let versions: [BinaryVersion]

    init(name: String, versions: [BinaryVersion]) {
        self.name = name
        self.versions = versions
    }

    static func parse(_ pv: ParseValue) -> [BinaryChannel] {
        var arr : [BinaryChannel] = []
        guard case .Map(let map) = pv else { fatalError("Non-map binary channels")}
        for (channel,cm) in map {
            guard case .Map(let channelMap) = cm else {fatalError("Non-map for channel \(channel)")}
            var channelArray: [BinaryVersion] = []
            for(version, vm) in channelMap {
                guard case .Map(let versionMap) = vm else { fatalError("Non-map for version \(channel).\(version)")}
                guard let u = versionMap["url"] else {fatalError("No url for binary version \(version)")}
                guard case .StringLiteral(let us) = u else { fatalError("Non-string value \(u) for url")}
                let url = URL(string: us)
                let version = BinaryVersion(version: version, url: url)
                channelArray.append(version)
            }
            let bc = BinaryChannel(name: channel, versions: channelArray)
            arr.append(bc)
        }
        return arr
    }
}

///A pointer to an individual binary release tarball
public struct BinaryVersion {
    public let version: String
    public let url: URL
}