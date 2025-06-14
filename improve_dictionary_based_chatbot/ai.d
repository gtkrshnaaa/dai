module ai;

import std.array;
import std.algorithm;
import std.conv;
import std.format;
import std.range;
import std.typecons;
import std.string;
import std.math;
import dictionary : Entry;

/// Simple tokenizer: lowercase and strip punctuation
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

struct SemanticRelation {
    string relatedToken;
    double relevance;
}

/// Core knowledge structure
struct Knowledge {
    string token;           // the token itself
    double weight;          // base importance
    string origin;          // parent word (source of meaning)
    string[][] exampleTokens;
    string[] definitionTokens;
    SemanticRelation[] related;
}

struct Model {
    Knowledge[] knowledge;
}

/// Train model from dictionary
Model trainModel(Entry[] dict) {
    Model M;

    foreach (entry; dict) {
        auto wordToken = tokenize(entry.word);
        auto defTokens = tokenize(entry.definition);
        string[][] exTokens;
        foreach (ex; entry.examples)
            exTokens ~= tokenize(ex);

        // Parent word entry
        foreach (t; wordToken) {
            M.knowledge ~= Knowledge(t, entry.weight, entry.word, exTokens, defTokens, []);
        }

        // Definition token knowledge
        foreach (t; defTokens) {
            M.knowledge ~= Knowledge(t, entry.weight * 0.7, entry.word, exTokens, defTokens, []);
        }

        // Example token knowledge
        foreach (ex; exTokens)
            foreach (t; ex)
                M.knowledge ~= Knowledge(t, entry.weight * 0.5, entry.word, exTokens, defTokens, []);
    }

    buildRelations(M.knowledge);
    return M;
}

/// Build semantic relations for each token
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

/// Match input tokens semantically
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

/// Score a single token against all matched knowledge
double tokenScore(string token, Knowledge[] matched) {
    double score = 0;
    foreach (k; matched) {
        double w = k.weight;
        if (k.token == token) score += w;
        else if (k.definitionTokens.canFind(token)) score += w * 0.7;
        else if (k.exampleTokens.joiner.canFind(token)) score += w * 0.5;
        foreach (r; k.related)
            if (r.relatedToken == token)
                score += w * r.relevance * 0.3;
    }
    return score;
}

/// Create n-gram fragments
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

/// Compose response using most relevant fragment
string composeReply(Knowledge[] matched, string[] inputTokens) {
    string[][] candidates;
    foreach (k; matched)
        foreach (ex; k.exampleTokens)
            candidates ~= generateNgrams(ex, 3, 8);

    Tuple!(string[], double)[] scored;
    foreach (frag; candidates) {
        double score = 0;
        foreach (t; frag)
            score += tokenScore(t, matched);

        // additional context boost: prefer fragments with dense input token match near center
        int cnt = cast(int) frag.count!(t => inputTokens.canFind(t));
        double centerBoost = 0;
        foreach (idx, t; frag)
            if (inputTokens.canFind(t))
                centerBoost += 1.0 - abs(idx - frag.length / 2.0) / frag.length;

        score += cnt * 0.5 + centerBoost;
        scored ~= tuple(frag, score);
    }

    scored.sort!((a, b) => b[1] < a[1]);
    if (scored.empty) return "unknown";
    return scored[0][0].join(" ");
}

/// Main reply logic
string generateSemanticReply(Model M, string input, ref string log) {
    auto tokens = tokenize(input);
    auto matched = matchTokens(M, tokens);
    if (matched.empty) {
        log = "[Thinking] No known tokens.\n";
        return "unknown";
    }

    auto reply = composeReply(matched, tokens);
    log = format(
        "[Thinking]\n- Input: %s\n- Matched: %s\n- Response frag: %s\n\n",
        tokens, matched.map!(k => k.token).to!string, reply
    );
    return reply;
}
