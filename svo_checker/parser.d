module parser;

/// Simple structure to represent a basic sentence in Subject-Verb-Object format
struct SentenceStructure {
    string subject;
    string verb;
    string object;
}

/// Heuristic-based parser: attempts to extract the last 3 tokens as a valid SVO sentence
bool parse(string[] tokens, ref SentenceStructure result) {
    if (tokens.length < 3)
        return false;

    // Try scanning from the end to find a valid sentence candidate
    // For example: "... i love d." → i = subject, love = verb, d = object

    // Take the last 3 tokens
    auto t = tokens[$ - 3 .. $];

    // Clean up punctuation from the object if any (e.g., remove '.' or ',')
    auto obj = t[2];
    if (obj.length > 1 && (obj[$ - 1] == '.' || obj[$ - 1] == ',')) {
        obj = obj[0 .. $ - 1];
    }

    // Assign components to the sentence structure
    result.subject = t[0];
    result.verb    = t[1];
    result.object  = obj;

    return true;
}
