# **Semantic Dictionary-based AI Chatbot**

**Concept Book (v0.1)**

---

#### **1. Introduction**

* **Project Name**: *(~i don't have any idea yet)*
* **Language**: D Programming Language
* **Goal**: To build a dictionary-driven semantic AI chatbot that generates human-like replies based on word definitions and usage examples, without using any fixed templates or deep learning frameworks.
* **Why**: This project aims to simulate true understanding using symbolic and statistical learning directly from human-curated data (dictionary).

---

#### **2. Core Philosophy**

* **No hardcoded response templates**
* **No machine learning libraries or GPU dependencies**
* **Pure CPU-based semantic logic**
* **All output is generated based on the understanding of meanings and usage**
* **Dictionary is the only source of knowledge**

---

#### **3. Architecture Overview**

* **Modules:**

  * `main.d`: Entry point, handles I/O, loads dictionary and history
  * `dictionary.d`: Loads structured dictionary data from JSON
  * `ai.d`: Core semantic engine (tokenizer, trainer, responder)
  * `store/`: Persistent storage (dictionary, conversation history)

* **Processing Flow:**

  ```
  User Input
       ↓
  Tokenizer → Matched Tokens → Semantic Mapping (definition & examples)
       ↓
  Knowledge Aggregation → Weighted Scoring → Top Keywords → Generated Reply
       ↓
  Output + Thinking Log
  ```

---

#### **4. Data Format: Dictionary Entries**

```json
{
  "word": "belajar",
  "definition": "proses memperoleh pengetahuan atau keterampilan.",
  "examples": [
    "Saya belajar bahasa pemrograman setiap hari.",
    "Dia belajar untuk ujian matematika.",
    "Kami belajar bersama di perpustakaan."
  ],
  "pos": "verb",
  "category": "aktivitas",
  "weight": 1.0
}
```

* **Fields:**

  * `word`: Base word
  * `definition`: Short, clear meaning
  * `examples`: At least 3 usage examples
  * `pos`: Part of speech
  * `category`: Semantic group
  * `weight`: Importance score (used for weighting in reply generation)

---

#### **5. Semantic Reply Generation**

* Tokenize input
* Match tokens with dictionary entries
* Collect all definitions and examples of matched words
* Tokenize all collected texts
* Count token frequency
* Multiply frequency with original word weight
* Sort and pick top tokens
* Generate reply from top-ranked tokens

---

#### **6. Thinking Log (Transparency)**

* The system always prints:

  * Input tokens
  * Matched dictionary tokens
  * Token frequency and scoring
  * Final generated reply (no random or hidden generation logic)

---

#### **7. Limitations**

* Word order is not context-sensitive (yet)
* Responses may be awkward if dictionary coverage is sparse
* Semantic structure is shallow (based on frequency and weight, not syntax)

---

#### **8. Future Enhancements**

* Context chaining between replies
* Semantic cluster analysis
* Improved scoring beyond raw frequency
* Memory system to retain previous dialogue themes
* POS-aware sentence construction


