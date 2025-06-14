module ai;

import std.array;
import std.algorithm;
import std.range;
import std.conv;
import std.json;
import std.format;
import std.typecons;
import dictionary : Entry;

/// Stopword list
bool isStopWord(string w) {
    return ["dan", "ke", "di", "yang", "itu", "ini", "untuk", "dengan"].canFind(w);
}

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
struct SemanticRelation {
    string relatedToken;
    double relevance;
}

struct Knowledge {
    string token;
    double weight;
    string[] definitionTokens;
    string[][] exampleTokens;
    SemanticRelation[] related;
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
            M.knowledge ~= Knowledge(t, e.weight, defT, exT, []);
        }
    }

    buildRelations(M.knowledge);
    return M;
}

/// Build relation strength between tokens
void buildRelations(ref Knowledge[] knowledge) {
    foreach (i, k; knowledge) {
        string[] context;
        context ~= k.definitionTokens;
        foreach (ex; k.exampleTokens)
            context ~= ex;

        int[string] counts;
        foreach (word; context)
            if (word != k.token)
                counts[word]++;

        SemanticRelation[] rels;
        foreach (word, count; counts) {
            double relevance = cast(double) count / context.length;
            rels ~= SemanticRelation(word, relevance);
        }
        knowledge[i].related = rels;
    }
}

/// Compose reply using knowledge from multiple tokens
string composeReply(Knowledge[] matched) {
    string[] allTokens;
    foreach (k; matched) {
        allTokens ~= k.definitionTokens;
        foreach (ex; k.exampleTokens)
            allTokens ~= ex;
        foreach (r; k.related)
            allTokens ~= r.relatedToken;
    }

    int[string] freq;
    foreach (t; allTokens)
        freq[t] += 1;

    auto scored = freq
        .byKeyValue
        .map!( (kv) {
            double w = matched
                .filter!(k => k.definitionTokens.canFind(kv.key) ||
                              k.exampleTokens.joiner.canFind(kv.key) ||
                              k.related.map!(r => r.relatedToken).canFind(kv.key))
                .map!(k => k.weight)
                .sum;
            return tuple(kv.key, kv.value * w);
        })
        .array;

    scored.sort!((a, b) => b[1] < a[1]);

    auto top = scored
        .filter!(t => !isStopWord(t[0]))
        .take(5)
        .map!(t => t[0])
        .array;

    if (top.length == 0)
        return "I'm not sure what that refers to.";


    return top.join(" ");

}

/// Generate semantic reply without templates
string generateSemanticReply(Model M, string input, ref string log) {
    auto toks = tokenize(input);
    Knowledge[] matched;
    foreach (t; toks) {
        auto found = M.knowledge.find!(k => k.token == t);
        if (found && !found.ptr.token.empty)
            matched ~= *found.ptr;
    }

    if (matched.empty) {
        log = "[Thinking] no known tokens.\n";
        return "Sorry, I didn't understand that.";
    }

    string reply = composeReply(matched);

    log = format(
        "[Thinking]\n" ~
        "- Input tokens: %s\n" ~
        "- Matched: %s\n" ~
        "- Top tokens: %s\n\n",
        toks,
        matched.map!(k => k.token).to!string,
        reply
    );

    return reply;
}
