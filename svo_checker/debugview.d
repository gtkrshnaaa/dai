module debugview;

import std.stdio;
import parser : SentenceStructure;

/// Displays the raw input sentence
void showInput(string input) {
    writeln("[Input] Raw sentence: \"", input, "\"");
}

/// Displays the tokenized words from the input sentence
void showTokens(string[] tokens) {
    writeln("\n== Stage 1: Tokenizing ==");
    writeln("Total tokens: ", tokens.length);
    foreach (i, token; tokens) {
        writeln("  Token[", i, "]: ", token);
    }
}

/// Displays the parsed sentence structure (Subject, Verb, Object)
void showParsed(SentenceStructure s) {
    writeln("\n== Stage 2: Parsing ==");
    writeln("Parsed structure:");
    writeln("  Subject : ", s.subject);
    writeln("  Verb    : ", s.verb);
    writeln("  Object  : ", s.object);
}

/// Displays the final sentence generated from the structure
void showFinalSentence(string sentence) {
    writeln("\n== Stage 3: Generating sentence ==");
    writeln("Final sentence: ", sentence);
}
