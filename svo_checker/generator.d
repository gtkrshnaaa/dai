module generator;

import parser : SentenceStructure;

/// Reconstructs a sentence from a simple SVO (Subject-Verb-Object) structure
string generate(SentenceStructure s) {
    // Join subject, verb, and object with spaces, and end with a period
    return s.subject ~ " " ~ s.verb ~ " " ~ s.object ~ ".";
}
