private enum ParseState {
    case Initial
    case Escaped
    case Dollar
    case SubstitutionName
}

private func evaluateSubstitution(substitution: String, package: Package) -> String {
    //"prefix-like" substitions here
    //collect sources substition
    if substitution.hasPrefix("collect_sources:") {
        let taskName = String(substitution.characters[substitution.characters.startIndex.advanced(by: 16)..<substitution.characters.endIndex])
        guard let task = package.tasks[taskName] else {
            fatalError("Cannot find task named \(taskName) for substition.")
        }
        guard let sources = task["sources"]?.vector else {
            fatalError("No sources for task named \(taskName) for substition.")
        }
        var str_sources: [String] = []
        for str in sources {
            guard let str_s = str.string else {
                fatalError("Non-string source \(str) for substition.")
            }
            str_sources.append(str_s)
        }
        let collectedSources = collectSources(sourceDescriptions: str_sources, taskForCalculatingPath: task)
        var output = ""
        for (idx, source) in collectedSources.enumerated() {
            output += source
            if idx != collectedSources.count - 1 { output += " "}
        }
        return output
    }

    //"constant" substitions here
    switch(substitution) {
        case "test_substitution":
        return "test_substitution"
        default:
        fatalError("Unknown substitiution \(substitution)")
    }
}

public func evaluateSubstitutions(input: String, package: Package)-> String {
    var output = ""
    var currentSubstitionName = ""
    var parseState = ParseState.Initial
    //introducing, the world's shittiest parser
    for char in input.characters {
        switch(parseState) {
            case .Initial:
                switch(char) {
                    case "$":
                        parseState = .Dollar
                    case "\\":
                        parseState = .Escaped
                    default:
                        output.characters.append(char)
                }

            case .Escaped:
                output.characters.append(char)
                parseState = .Initial

            case .Dollar:
                switch(char) {
                    case "{":
                        parseState = .SubstitutionName
                    case "\\":
                        output.characters.append("$")
                        parseState = .Escaped
                    default:
                        output.characters.append("$")
                        output.characters.append(char)
                        parseState = .Initial

                }
            case .SubstitutionName:
                switch(char) {
                    case "}":
                        output += evaluateSubstitution(substitution: currentSubstitionName, package: package)
                        currentSubstitionName = ""
                        parseState = .Initial
                    default:
                        currentSubstitionName.characters.append(char)
                }
        }
    }
    return output
}