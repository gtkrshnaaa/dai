module ai;

import std.array;
import std.algorithm;
import std.conv;
import std.format;
import std.range;
import std.math;
import std.typecons;
import dictionary : Entry;

/// Tokenize string into lowercase words, removing punctuation
string[] tokenize(string s) {
    immutable delims = " .,!?";
    string cur;
    string[] tokens;
    foreach (c; s) {
        if (delims.canFind(c)) {
            if (!cur.empty) tokens ~= cur;
            cur = "";
        } else {
            cur ~= (c >= 'A' && c <= 'Z' ? cast(char)(c + 32) : c);
        }
    }
    if (!cur.empty) tokens ~= cur;
    return tokens;
}

/// Semantic knowledge structures
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
struct Model {
    Knowledge[] knowledge;
}

/// Train model from dictionary
Model trainModel(Entry[] dict) {
    Model M;
    foreach (entry; dict) {
        auto defTokens = tokenize(entry.definition);
        string[][] exampleTokens;
        foreach (ex; entry.examples)
            exampleTokens ~= tokenize(ex);

        foreach (t; tokenize(entry.word)) {
            M.knowledge ~= Knowledge(t, entry.weight, defTokens, exampleTokens, []);
        }
    }
    buildRelations(M.knowledge);
    return M;
}

/// Build relations between tokens using definitions and examples
void buildRelations(ref Knowledge[] knowledge) {
    foreach (i, k; knowledge) {
        string[] context = k.definitionTokens ~ k.exampleTokens.joiner.array;
        int[string] counts;
        foreach (w; context)
            if (w != k.token) counts[w]++;

        SemanticRelation[] rels;
        foreach (w, c; counts)
            rels ~= SemanticRelation(w, cast(double)c / context.length);
        knowledge[i].related = rels;
    }
}

/// Match input tokens with known tokens or semantic relations
Knowledge[] matchTokens(Model M, string[] input) {
    Knowledge[] matched;
    foreach (t; input) {
        auto found = M.knowledge.find!(k => k.token == t);
        if (found) matched ~= *found.ptr;
        else {
            foreach (k; M.knowledge)
                foreach (r; k.related)
                    if (r.relatedToken == t && r.relevance > 0.3)
                        matched ~= k;
        }
    }
    return matched;
}

/// Score a token across all matched entries
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

/// Generate n-gram fragments from token array
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

/// Score n-gram fragment based on token match and structure
double scoreFragment(string[] frag, string[] inputTokens, Knowledge[] matched) {
    double tokenScoreSum = 0;
    double positionScore = 0;
    double structureBonus = 0;

    foreach (t; frag)
        tokenScoreSum += tokenScore(t, matched);

    // Boost if tokens are centered around match
    foreach (idx, t; frag) {
        if (inputTokens.canFind(t)) {
            double center = frag.length / 2.0;
            positionScore += 1.0 - abs(idx - center) / frag.length;
        }
    }

    // Small bonus for known sentence-like patterns
    if (frag.length > 3 && frag[0] == "saya") structureBonus += 0.3;
    if (frag.canFind("dan")) structureBonus += 0.2;
    if (frag[$ - 1] == "guru" || frag[$ - 1] == "teman") structureBonus += 0.2;

    return tokenScoreSum + positionScore + structureBonus;
}

/// Compose a reply from scored n-gram fragments
string composeReply(Knowledge[] matched, string[] inputTokens) {
    string[][] candidates;
    foreach (k; matched)
        foreach (ex; k.exampleTokens)
            candidates ~= generateNgrams(ex, 3, 10);

    Tuple!(string[], double)[] scored;
    foreach (frag; candidates) {
        double score = scoreFragment(frag, inputTokens, matched);
        scored ~= tuple(frag, score);
    }

    scored.sort!((a, b) => b[1] < a[1]);

    if (scored.empty) return "unknown";
    return scored[0][0].join(" ");
}

/// Generate semantic reply
string generateSemanticReply(Model M, string input, ref string log) {
    auto tokens = tokenize(input);
    auto matched = matchTokens(M, tokens);
    if (matched.empty) {
        log = "[Thinking] no known tokens.\n";
        return "unknown";
    }

    auto result = composeReply(matched, tokens);

    log = format(
        "[Thinking]\n- Input: %s\n- Matched: %s\n- Response frag: %s\n\n",
        tokens, matched.map!(k => k.token).to!string, result
    );
    return result;
}
