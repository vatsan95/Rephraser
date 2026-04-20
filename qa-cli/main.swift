import Foundation
import MLX
import MLXLLM
import MLXLMCommon

// MARK: - Config

struct TestCase {
    let name: String
    let input: String
    /// Which modes to run this input through. `nil` = all preset modes.
    let modes: [RephraseMode]?
}

let DEFAULT_MODEL_HF_ID = "mlx-community/gemma-3-1b-it-qat-4bit"

// Test inputs deliberately chosen to stress the two failure classes we fixed:
//   (A) preamble / meta-commentary leakage
//   (B) multi-sentence collapse, answering rhetorical questions, losing ALL-CAPS emphasis.
let testCases: [TestCase] = [
    TestCase(
        name: "multi_sentence_with_question_and_caps",
        input: "Did I understand the code? NO, but do I know what I wanted and what to ask, yes. I can figure it out as I go.",
        modes: nil
    ),
    TestCase(
        name: "hedged_three_sentences",
        input: "I think maybe we should ship it on Friday. Perhaps we should run one more test first. I'm kind of worried about the edge case with empty input.",
        modes: nil
    ),
    TestCase(
        name: "already_clean_single_sentence",
        input: "The build failed because the signing certificate expired yesterday.",
        modes: nil
    ),
    TestCase(
        name: "grammar_errors_with_caps",
        input: "this dont work on windows 10 but it does work on windows 11. DO NOT ship it untill we fix it.",
        modes: nil
    ),
]

// MARK: - Helpers

func log(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}

@MainActor
func loadContainer(hfID: String) async throws -> ModelContainer {
    log("[qa] loading model: \(hfID)")
    let config = ModelConfiguration(id: hfID)
    let container = try await LLMModelFactory.shared.loadContainer(configuration: config) { progress in
        if progress.fractionCompleted > 0 {
            log("[qa] download progress: \(Int(progress.fractionCompleted * 100))%")
        }
    }
    log("[qa] model loaded")
    return container
}

@MainActor
func runOne(container: ModelContainer, systemPrompt: String, userText: String) async throws -> String {
    let messages: [[String: String]] = [
        ["role": "system", "content": systemPrompt],
        ["role": "user", "content": userText]
    ]
    var output = ""
    try await container.perform { context in
        let input = try await context.processor.prepare(input: .init(messages: messages))
        // Use temperature 0 for reproducibility in the QA suite (prod uses 0.7).
        let params = GenerateParameters(temperature: 0.0)
        let stream = try MLXLMCommon.generate(input: input, parameters: params, context: context)
        for await gen in stream {
            if let chunk = gen.chunk { output += chunk }
            // Cap to keep the test bounded.
            if output.count > 2000 { break }
        }
    }
    return output
}

// MARK: - Scoring heuristics

struct Score {
    var passes: [String] = []
    var fails: [String] = []
    var warnings: [String] = []
    var passed: Bool { fails.isEmpty }
}

func sentenceCount(_ s: String) -> Int {
    // Naive sentence counter — terminal punctuation followed by whitespace or end of string.
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return 0 }
    // Split on . ! ? followed by space or end.
    let parts = trimmed.split(whereSeparator: { ".!?".contains($0) })
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    return max(parts.count, 1)
}

let preambleMarkers: [String] = [
    "here is", "here's", "sure,", "sure!", "certainly",
    "the text", "the input", "the message", "the highlighted text",
    "rephrased:", "rewritten:", "summary:",
    "this is the", "below is", "output:",
    "of course",
]

func score(input: String, output: String, mode: RephraseMode) -> Score {
    var s = Score()
    let lowerOutput = output.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    // Class A: preamble / meta-commentary check (all modes)
    let firstLine = lowerOutput.components(separatedBy: .newlines).first ?? ""
    var preambleHit = false
    for marker in preambleMarkers {
        if firstLine.hasPrefix(marker) {
            s.fails.append("Class A: output begins with preamble marker '\(marker)'")
            preambleHit = true
            break
        }
    }
    if !preambleHit { s.passes.append("Class A: no preamble detected") }

    // ALL CAPS preservation — only check when input actually has an ALL-CAPS emphasis word.
    // Class B applies to the 7 tone/grammar modes, not summarize/keyPoints.
    let applyClassB: Bool
    switch mode {
    case .summarize, .keyPoints: applyClassB = false
    default: applyClassB = true
    }

    let allCapsWords = input.components(separatedBy: .whitespacesAndNewlines)
        .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        .filter { $0.count >= 2 && $0 == $0.uppercased() && $0.contains(where: { $0.isLetter }) }

    if applyClassB && !allCapsWords.isEmpty {
        let preserved = allCapsWords.filter { output.contains($0) }
        if preserved.count == allCapsWords.count {
            s.passes.append("Class B: ALL-CAPS preserved (\(allCapsWords.joined(separator: ",")))")
        } else {
            let missing = Set(allCapsWords).subtracting(preserved)
            s.fails.append("Class B: ALL-CAPS lost: \(missing.sorted().joined(separator: ","))")
        }
    }

    // Sentence preservation (Class B, tone modes only).
    if applyClassB {
        let inN = sentenceCount(input)
        let outN = sentenceCount(output)
        if mode.id == "elaborate" {
            if outN >= inN {
                s.passes.append("Class B: sentence count \(inN)->\(outN) (elaborate, >=)")
            } else {
                s.fails.append("Class B: elaborate dropped sentences \(inN)->\(outN)")
            }
        } else if mode.id == "concise" {
            // Concise may shorten each sentence but shouldn't drop entire ideas.
            // Heuristic: allow 1 fewer, fail if more than 1 dropped.
            if outN >= inN - 1 {
                s.passes.append("Class B: sentence count \(inN)->\(outN) (concise)")
            } else {
                s.fails.append("Class B: concise dropped too many sentences \(inN)->\(outN)")
            }
        } else {
            if outN == inN {
                s.passes.append("Class B: sentence count preserved (\(inN))")
            } else {
                s.fails.append("Class B: sentence count changed \(inN)->\(outN)")
            }
        }
    }

    // Don't-answer-the-question check (Class B, applies when input contains '?').
    if applyClassB && input.contains("?") {
        if output.contains("?") {
            s.passes.append("Class B: question preserved as question")
        } else {
            s.warnings.append("Class B: input had '?' but output has none — may have answered")
        }
    }

    // FixGrammar length sanity — output roughly same word count as input.
    if mode.id == "fixGrammar" {
        let inWords = input.split(separator: " ").count
        let outWords = output.split(separator: " ").count
        let ratio = Double(outWords) / Double(max(inWords, 1))
        if ratio >= 0.7 && ratio <= 1.4 {
            s.passes.append("FixGrammar: length ratio \(String(format: "%.2f", ratio))")
        } else {
            s.fails.append("FixGrammar: length ratio out of range \(String(format: "%.2f", ratio)) (in=\(inWords) out=\(outWords))")
        }
    }

    // KeyPoints should start with '-'.
    if mode.id == "keyPoints" {
        let first = output.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " "
        if first == "-" || first == "•" || first == "*" {
            s.passes.append("KeyPoints: starts with bullet")
        } else {
            s.fails.append("KeyPoints: does not start with bullet (got '\(first)')")
        }
    }

    return s
}

// MARK: - Main

@MainActor
func main() async {
    // Parse args: --model <hf-id>
    var hfID = DEFAULT_MODEL_HF_ID
    let args = CommandLine.arguments
    var i = 1
    while i < args.count {
        if args[i] == "--model", i + 1 < args.count { hfID = args[i + 1]; i += 2 }
        else { i += 1 }
    }

    MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

    let container: ModelContainer
    do {
        container = try await loadContainer(hfID: hfID)
    } catch {
        log("[qa] FATAL: could not load model: \(error)")
        exit(1)
    }

    let modes = RephraseMode.allPresets

    var report = ""
    report += "# Rephraser mode QA report\n\n"
    report += "- Model: `\(hfID)`\n"
    report += "- Temperature: 0.0 (reproducible)\n"
    report += "- Date: \(ISO8601DateFormatter().string(from: Date()))\n\n"

    var totalPass = 0
    var totalFail = 0

    for tc in testCases {
        report += "## Test: `\(tc.name)`\n\n"
        report += "**Input:**\n\n> \(tc.input)\n\n"

        let useModes = tc.modes ?? modes
        for mode in useModes {
            log("[qa] running \(tc.name) x \(mode.id)")
            do {
                let start = Date()
                let output = try await runOne(container: container, systemPrompt: mode.systemPrompt, userText: tc.input)
                let elapsed = Date().timeIntervalSince(start)
                let s = score(input: tc.input, output: output, mode: mode)
                if s.passed { totalPass += 1 } else { totalFail += 1 }

                report += "### Mode: `\(mode.id)` \(s.passed ? "✅" : "❌") (\(String(format: "%.1fs", elapsed)))\n\n"
                report += "**Output:**\n\n```\n\(output.trimmingCharacters(in: .whitespacesAndNewlines))\n```\n\n"
                if !s.fails.isEmpty {
                    report += "**Fails:**\n"
                    for f in s.fails { report += "- \(f)\n" }
                    report += "\n"
                }
                if !s.warnings.isEmpty {
                    report += "**Warnings:**\n"
                    for w in s.warnings { report += "- \(w)\n" }
                    report += "\n"
                }
                if !s.passes.isEmpty {
                    report += "<details><summary>Passes (\(s.passes.count))</summary>\n\n"
                    for p in s.passes { report += "- \(p)\n" }
                    report += "\n</details>\n\n"
                }
            } catch {
                totalFail += 1
                report += "### Mode: `\(mode.id)` ❌ ERROR\n\n"
                report += "\(error)\n\n"
            }
        }
    }

    report += "---\n\n"
    report += "## Summary\n\n"
    report += "- Total mode×input runs: \(totalPass + totalFail)\n"
    report += "- Passed: \(totalPass)\n"
    report += "- Failed: \(totalFail)\n"

    let outPath = "qa-cli/results.md"
    try? report.write(toFile: outPath, atomically: true, encoding: .utf8)
    log("[qa] wrote \(outPath)")

    print(report)
    exit(totalFail == 0 ? 0 : 1)
}

await main()
