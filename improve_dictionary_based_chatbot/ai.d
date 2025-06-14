module ai;

import std.array;
import std.algorithm;
import std.conv;
import std.json;
import std.format;
import std.range;
import std.typecons;
import std.math : abs;
import dictionary : Entry;

/// Tokenize input by lowercasing and removing basic punctuation
string[] tokenize(string s) {
    immutable delimiters = " .,!?";
    string current;
    string[] tokens;
    foreach (c; s) {
        if (delimiters.canFind(c)) {
            if (!current.empty) tokens ~= current;
            current = "";
        } else {
            current ~= (c >= 'A' && c <= 'Z' ? cast(char)(c + 32) : c);
        }
    }
    if (!current.empty) tokens ~= current;
    return tokens;
}

/// Represents semantic relationships between tokens
struct SemanticRelation {
    string relatedToken;
    double relevance;
}

/// Knowledge structure for each token
struct Knowledge {
    string token;
    double weight;
    string[] definitionTokens;
    string[][] exampleTokens;
    SemanticRelation[] related;
}

/// The AI model: a collection of learned token knowledge
struct Model {
    Knowledge[] knowledge;
}

/// Build the model from the dictionary entries
Model trainModel(Entry[] dictionary) {
    Model model;
    foreach (entry; dictionary) {
        auto defTokens = tokenize(entry.definition);
        string[][] exampleTokens;
        foreach (ex; entry.examples)
            exampleTokens ~= tokenize(ex);

        foreach (t; tokenize(entry.word)) {
            model.knowledge ~= Knowledge(t, entry.weight, defTokens, exampleTokens, []);
        }
    }
    buildRelations(model.knowledge);
    return model;
}

/// Build semantic relationships among all known tokens
void buildRelations(ref Knowledge[] knowledge) {
    foreach (i, k; knowledge) {
        string[] context = k.definitionTokens ~ k.exampleTokens.joiner.array;
        int[string] frequency;
        foreach (w; context)
            if (w != k.token) frequency[w]++;
        SemanticRelation[] relations;
        foreach (w, count; frequency)
            relations ~= SemanticRelation(w, cast(double)count / context.length);
        knowledge[i].related = relations;
    }
}

/// Match input tokens with known tokens, including related fallback
Knowledge[] matchTokens(Model model, string[] inputTokens) {
    Knowledge[] matched;
    foreach (t; inputTokens) {
        auto direct = model.knowledge.find!(k => k.token == t);
        if (direct) matched ~= *direct.ptr;
        else {
            foreach (k; model.knowledge)
                foreach (r; k.related)
                    if (r.relatedToken == t && r.relevance > 0.3)
                        matched ~= k;
        }
    }
    return matched;
}

/// Score how relevant a token is across all matched knowledge
double tokenScore(string token, Knowledge[] matched) {
    double score = 0;
    foreach (k; matched) {
        double w = k.weight;
        if (k.definitionTokens.canFind(token)) score += w;
        else if (k.exampleTokens.joiner.canFind(token)) score += w * 0.8;
        else foreach (r; k.related)
            if (r.relatedToken == token) score += w * r.relevance * 0.5;
    }
    return score;
}

/// Generate all n-gram fragments from token list
string[][] generateNgrams(string[] tokens, int minLength, int maxLength) {
    string[][] ngrams;
    foreach (n; minLength .. maxLength + 1) {
        if (tokens.length < n) continue;
        foreach (i; 0 .. tokens.length - n + 1) {
            ngrams ~= tokens[i .. i + n];
        }
    }
    return ngrams;
}

/// Compose a reply by scoring fragments and choosing the best one
string composeReply(Knowledge[] matched, string[] inputTokens) {
    string[][] candidates;
    foreach (k; matched)
        foreach (ex; k.exampleTokens)
            candidates ~= generateNgrams(ex, 3, 10);

    if (candidates.empty) return "unknown";

    Tuple!(string[], double)[] scored;
    foreach (frag; candidates) {
        double baseScore = 0;
        int coverage = 0;
        foreach (t; frag) {
            baseScore += tokenScore(t, matched);
            if (inputTokens.canFind(t)) coverage++;
        }

        double positionBoost = 0;
        foreach (idx, t; frag) {
            if (inputTokens.canFind(t))
                positionBoost += 1.0 - abs(idx - frag.length / 2.0) / frag.length;
        }

        double totalScore = baseScore + coverage + positionBoost;
        scored ~= tuple(frag, totalScore);
    }

    scored.sort!((a, b) => b[1] < a[1]);
    return scored[0][0].join(" ");
}

/// Main function to generate a semantic reply from the model
string generateSemanticReply(Model model, string input, ref string log) {
    auto tokens = tokenize(input);
    auto matched = matchTokens(model, tokens);
    if (matched.empty) {
        log = "[Thinking] no known tokens.\n";
        return "unknown";
    }

    auto reply = composeReply(matched, tokens);

    log = format(
        "[Thinking]\n- Input: %s\n- Matched: %s\n- Response frag: %s\n\n",
        tokens, matched.map!(k => k.token).to!string, reply
    );
    return reply;
}
