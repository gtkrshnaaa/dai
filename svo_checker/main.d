import std.stdio;
import std.string : strip;

import tokenizer;
import parser;
import generator;
import debugview;

void main() {
    writeln("== AI Sentence Processor ==");

    writeln("Enter a sentence (example: I love D): ");
    string input = readln().strip();

    showInput(input);

    auto tokens = tokenize(input);
    showTokens(tokens);

    SentenceStructure parsed;
    if (!parse(tokens, parsed)) {
        writeln("Parsing failed: Sentence too short or invalid format.");
        return;
    }

    showParsed(parsed);

    auto result = generate(parsed);
    showFinalSentence(result);
}
