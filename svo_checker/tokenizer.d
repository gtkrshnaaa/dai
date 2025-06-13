module tokenizer;

import std.array : array;
import std.algorithm : splitter;

/// Splits the input sentence into tokens (words) based on spaces
string[] tokenize(string sentence) {
    // Use splitter to lazily split by space, then convert to array
    return sentence.splitter(" ").array;
}
