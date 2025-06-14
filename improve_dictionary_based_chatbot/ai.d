module ai;

import std.array;
import std.algorithm;
import std.conv;
import std.json;
import std.format;
import std.math : abs;
import std.range;
import std.typecons : Tuple;
import dictionary : Entry;

/// tokenizer: lowercase + strip punctuation
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

/// knowledge structures
struct SemanticRelation { string relatedToken; double relevance; }
struct Knowledge {
    string token;
    double weight;
    string[] definitionTokens;
    string[][] exampleTokens;
    SemanticRelation[] related;
}
struct Model { Knowledge[] knowledge; }

Model trainModel(Entry[] dict) {
    Model M;
    foreach (e; dict) {
        auto defT = tokenize(e.definition);
        string[][] exT;
        foreach (ex; e.examples) exT ~= tokenize(ex);
        foreach (t; tokenize(e.word))
            M.knowledge ~= Knowledge(t, e.weight, defT, exT, []);
    }
    buildRelations(M.knowledge);
    return M;
}

void buildRelations(ref Knowledge[] knowledge) {
    foreach (i, k; knowledge) {
        string[] ctx = k.definitionTokens ~ k.exampleTokens.joiner.array;
        int[string] counts;
        foreach (w; ctx) if (w != k.token) counts[w]++;
        SemanticRelation[] rels;
        foreach (w, c; counts) rels ~= SemanticRelation(w, cast(double)c / ctx.length);
        knowledge[i].related = rels;
    }
}

Knowledge[] matchTokens(Model M, string[] input) {
    Knowledge[] matched;
    foreach (t; input) {
        auto found = M.knowledge.find!(k => k.token == t);
        if (found) matched ~= *found.ptr;
        else foreach (k; M.knowledge) foreach (r; k.related)
            if (r.relatedToken == t && r.relevance > 0.3) matched ~= k;
    }
    return matched.uniq.array;
}

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

string[][] generateNgrams(string[] tokens, int minLen, int maxLen) {
    string[][] ngrams;
    foreach (n; minLen .. maxLen + 1) {
        if (tokens.length < n) continue;
        foreach (i; 0 .. tokens.length - n + 1)
            ngrams ~= tokens[i .. i + n].array;
    }
    return ngrams;
}

string composeReply(Knowledge[] matched, string[] inputTokens) {
    struct Fragment { string[] tokens; int matchCount; double score; }
    Fragment[] fragments;

    foreach (k; matched) {
        foreach (sent; k.exampleTokens) {
            int mc = cast(int) sent.count!(t => inputTokens.canFind(t));
            if (mc == 0) continue;
            foreach (frag; generateNgrams(sent, 2, 6)) {
                int m2 = cast(int) frag.count!(t => inputTokens.canFind(t));
                if (m2 == 0) continue;

                double sc = m2 * 2.0; // match bonus
                foreach (idx, t; frag) {
                    double pw = 1.0 - abs(idx - frag.length/2) / frag.length;
                    sc += tokenScore(t, matched) * pw;
                }
                if (frag.length >= 3) sc *= 1.2; // length bonus
                fragments ~= Fragment(frag, m2, sc);
            }
        }
    }

    if (fragments.empty) return "unknown";
    fragments.sort!((a, b) => b.score < a.score);
    return fragments[0].tokens.join(" ");
}

string generateSemanticReply(Model M, string input, ref string log) {
    auto toks = tokenize(input);
    auto matched = matchTokens(M, toks);
    if (matched.empty) {
        log = "[Thinking] no known tokens.\n";
        return "unknown";
    }
    auto frag = composeReply(matched, toks);
    log = format(
        "[Thinking]\n- Input: %s\n- Matched: %s\n- Response frag: %s\n\n",
        toks, matched.map!(k => k.token).to!string, frag
    );
    return frag;
}
