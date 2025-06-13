module dictionary;

import std.file;
import std.json;
import std.array;
import std.algorithm;
import std.conv;

struct Entry {
    int id;
    string word;
    string definition;
    string[] examples;
    string pos;
    string category;
    double weight;
}

Entry[] loadDictionary(string path) {
    auto content = readText(path);
    auto arr = parseJSON(content).array;
    Entry[] entries; int id = 1;

    foreach(e; arr) {
        entries ~= Entry(id++, e["word"].str, e["definition"].str,
            e["examples"].array.map!(x => x.str).array,
            e["pos"].str, e["category"].str, e["weight"].floating);
    }
    return entries;
}
