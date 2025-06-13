import std.stdio;
import std.json;
import std.file;
import dictionary : loadDictionary, Entry;
import ai : trainModel, generateSemanticReply;

/// Strip newline from user input
string stripNewline(string s) {
    import std.algorithm;
    return s.endsWith("\n") ? s[0 .. $-1] : s;
}

void main() {
    // Load dictionary and train the model
    Entry[] dictionary = loadDictionary("store/dictionary.json");
    auto model = trainModel(dictionary);

    // Load history
    string historyContent = readText("store/history.json");
    JSONValue[] history;
    try {
        auto json = parseJSON(historyContent);
        history = json.type == JSONType.array ? json.array : [];
    } catch(Throwable) {
        history = [];
    }

    writeln("Hi! Ask me something. Type 'exit' to quit.");

    while(true) {
        write("> ");
        string input = stripNewline(readln());
        if(input == "exit") break;

        string thinkingLog;
        string reply = generateSemanticReply(model, input, thinkingLog);
        writeln(thinkingLog ~ reply ~ "\n");

        // Append to history
        history ~= JSONValue([
            "user": JSONValue(input),
            "thinking": JSONValue(thinkingLog),
            "reply": JSONValue(reply)
        ]);

        // Save back to file
        auto file = File("store/history.json", "w");
        file.write(JSONValue(history).toString());
        file.close();
    }

    writeln("Bye!");
}
