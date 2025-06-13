module ai;

import std.array;
import std.algorithm;
import std.conv;
import std.json;
import std.format;
import std.typecons;
import dictionary : Entry;

/// Simple tokenizer: lowercase + split punctuation
string[] tokenize(string s) {
    immutable delims = " .,!?";
    string cur;
    string[] toks;
    foreach (c; s) {
        if (delims.canFind(c)) {
            if (!cur.empty) toks ~= cur;
            cur = "";
        } else cur ~= (c >= 'A' && c <= 'Z' ? cast(char)(c + 32) : c);
    }
    if (!cur.empty) toks ~= cur;
    return toks;
}

/// Learned semantic info per token
struct Knowledge {
    string token;
    double weight;
    string[] definitionTokens;
    string[][] exampleTokens;
}

/// Semantic model built from dictionary
struct Model {
    Knowledge[] knowledge;
}

/// Train model using definitions and examples
Model trainModel(Entry[] dict) {
    Model M;
    foreach (e; dict) {
        auto defT = tokenize(e.definition);
        string[][] exT;
        foreach (ex; e.examples)
            exT ~= tokenize(ex);

        foreach (t; tokenize(e.word)) {
            M.knowledge ~= Knowledge(t, e.weight, defT, exT);
        }
    }
    return M;
}

/// Compose reply using knowledge from multiple tokens
string composeReply(Knowledge[] matched) {
    string[] allTokens;
    foreach (k; matched) {
        allTokens ~= k.definitionTokens;
        foreach (ex; k.exampleTokens)
            allTokens ~= ex;
    }

    int[string] freq;
    foreach (t; allTokens)
        freq[t] += 1;

    auto scored = freq
        .byKeyValue
        .map!( (kv) {
            double w = matched
                .filter!(k => k.definitionTokens.canFind(kv.key) ||
                              k.exampleTokens.joiner.canFind(kv.key))
                .map!(k => k.weight)
                .sum;
            return tuple(kv.key, kv.value * w);
        })
        .array;

    scored.sort!((a, b) => b[1] < a[1]);

    auto top = scored[0 .. min(4, scored.length)];
    string reply = top.map!(t => t[0]).join(" ");
    return reply ~ ".";
}


/// Generate semantic reply without templates
string generateSemanticReply(Model M, string input, ref string log) {
    auto toks = tokenize(input);
    Knowledge[] matched;
    foreach (t; toks) {
        auto found = M.knowledge.find!(k => k.token == t);
        if (found) matched ~= *found.ptr;
    }

    if (matched.empty) {
        log = "[Thinking] no known tokens.\n";
        return "Sorry, I didn't understand that.";
    }

    // Compose reply using combined meanings
    string reply = composeReply(matched);

    log = format(
        "[Thinking]\n" ~
        "- Input tokens: %s\n" ~
        "- Matched tokens: %s\n\n",
        toks, matched.map!(k => k.token).to!string
    );

    return reply;
}
