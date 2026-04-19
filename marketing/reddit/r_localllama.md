# r/LocalLLaMA

**Subreddit:** https://www.reddit.com/r/LocalLLaMA/
**Rules:** Technical audience. Lead with the stack + benchmarks. No marketing-speak ever. Mods remove low-effort self-promo fast.
**Flair:** "Resources" or "Other"

---

## Title

> I wrote a system-wide text rephraser that runs Gemma 3 / Qwen 3 / Phi-4 locally via MLX (Mac) and llama.cpp (Windows). Free, MIT.

## Body

Hey all. Long-time lurker. Built something I wish existed when I started
using local LLMs for real work — a menu bar / tray app that lets you
rephrase selected text anywhere in the OS with `⌥⇧R` / `Ctrl+Alt+R`.

**The stack**

| Platform | Inference | Runtime | Binary |
|----------|-----------|---------|--------|
| macOS 14+ | Apple MLX | Swift + SwiftUI | ~8 MB app + model |
| Windows 10/11 | llama-cpp-2 (Rust bindings) | Tauri 2 + Rust | ~15 MB MSI + model |

Mac uses MLX because it's 2–3× faster than llama.cpp on Apple Silicon
(Metal graph fusion). Windows uses llama.cpp because MLX is Apple-only,
and llama.cpp CPU inference is "good enough" for interactive rephrases
even on a 4-core Intel laptop.

**Model catalog (user-picked at first launch)**
- Qwen 2.5 0.5B Q4_K_M (400 MB, ~15 tok/s on M2)
- Gemma 3 1B Q4_K_M (800 MB, ~12 tok/s) — default
- Phi-4 Mini Q4_K_M (2.3 GB)
- Llama 3.2 3B Instruct Q4_K_M (1.8 GB)
- Qwen 3 4B Q4_K_M (2.5 GB)
- Gemma 3 4B Q4_K_M (2.5 GB)

All models use ChatML on Qwen/Phi/Gemma, Llama-3 format on Llama 3.2.
2048 ctx, 384 max new tokens, temperature 0.2, top-p 0.9. Greedy sampling
on Windows (saves a few percent CPU), nucleus on Mac.

**The annoying details**
- **Clipboard preservation:** on both OSes, I snapshot the clipboard,
  synthesize Ctrl+C, wait for a change signal (200ms timeout), run
  inference, then restore — so your Ctrl+V keeps whatever you had
  pre-rephrase. Windows uses arboard + enigo, Mac uses NSPasteboard +
  CGEvent.
- **Prompt injection mitigation:** user text is wrapped in sentinel
  markers `<<<USER_TEXT_BEGIN>>>` / `<<<END>>>` with a system prompt
  telling the model to treat the content as data, not instructions.
  ChatML role tags are stripped from input before tokenization.
- **GGUF supply chain:** SHA-256 verification framework is in
  `shared/models/catalog.json` — digests are blank in v0.1 (TLS-only
  trust) but the verifier is wired; I'll populate from HF's lfs.oid
  field once I confirm bartowski's hashes are stable across re-uploads.
- **Streaming cancel:** an `AtomicBool` is checked every decoded token so
  hitting Escape aborts inference within one step (<80 ms typical).

**Why no Linux**
Time and a Wayland hotkey-registration rabbit hole I wasn't ready for.
Contributions welcome — `windows/app/src-tauri/src/hotkey.rs` is tiny
and Linux-friendly with `global-hotkey` crate.

**Repo:** https://github.com/vatsan95/Rephraser
**Downloads:** https://vatsan95.github.io/Rephraser/

I'd especially love feedback on:
- Prompt format per-model (I'm hand-tuning ChatML; anyone have better
  Gemma-3 instruct prompts?)
- Speculative decoding — worth adding? Tokens are short enough that I'm
  not sure it's a win.
- Distilled 0.3B models that don't mangle rephrases. Anything smaller
  than Qwen 2.5 0.5B that actually works?

## First comment

> For anyone curious about the full prompt layout, it's at shared/prompts/modes.json in the repo — nine tones with JSON-escaped system prompts tuned on ~50 pairs of golden examples. PRs to improve them are welcome; I'm especially unsatisfied with "creative mode" on Gemma 3.

## Reply playbook

- **"Why not Ollama as the backend?"** → "Bundling llama.cpp statically means a single 15 MB installer with zero external deps. Ollama adds a ~300 MB daemon."
- **"Why not just Open WebUI?"** → "Web UI means alt-tab. The point is no alt-tab — inline rephrase in whatever app you're already in."
- **"Benchmarks vs Grammarly?"** → "Different tool. Grammarly corrects; Rephraser rewrites. If you want grammar check specifically, Grammarly is better and will stay better."
