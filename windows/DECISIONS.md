# Windows Port — Decision Log

Append-only log of architectural decisions for the Rephraser Windows app.
Each entry: date, decision, context, consequences.

---

## 2026-04-18 — Stack: Tauri 2 + Rust + llama.cpp

**Context:** Mac app is Swift + SwiftUI + Apple MLX, none of which port to Windows. Need a new stack that:
- Builds on GitHub Actions `windows-latest` (user has no Windows machine)
- Small installer (<20 MB without model)
- On-device inference (no cloud, same privacy guarantee as Mac)
- Cross-platform potential (eventually unify with Mac)

**Alternatives considered:**
1. Electron + `node-llama-cpp` — ~100 MB installer, slower startup, but well-trodden
2. Native C#/WPF + ONNX Runtime DirectML — best perf, needs Windows-native build env
3. Python + PyQt + `llama-cpp-python` — fastest to prototype but bundling is painful
4. **Tauri 2 + Rust + `llama-cpp-2`** ← chosen

**Rationale:**
- Tauri installer ~12 MB (vs 100 MB Electron)
- Rust memory safety + strong async story
- `llama-cpp-2` wraps battle-tested GGUF inference
- Tauri has built-in tray, single-instance, updater, signing
- Can cross-build Windows from any host via GHA
- Same Rust codebase could later target macOS (unify stacks)

**Consequences:**
- Dev team must learn Rust + Tauri
- `llama-cpp-2` requires CMake + MSVC toolchain in CI (adds ~5 min build time)
- GGUF output may differ slightly from MLX (mitigated by golden tests — see Phase 0)

**Gate:** See `.github/workflows/windows-poc.yml`. If Phase 0 PoC fails to meet:
- Model loads <1.5 GB RAM
- Streaming ≥3 tok/s on CPU
- Binary <80 MB

... then switch to `mistral.rs` (pure-Rust) or `candle` (HuggingFace) before Phase 1.

---

## 2026-04-18 — Repo layout: monorepo under `windows/`

**Decision:** Keep Mac (Swift) and Windows (Rust/TS) in the same repo; Windows lives under `/windows`, shared assets under `/shared`, website under `/docs` (existing).

**Alternatives:**
- Separate `Rephraser-Windows` repo — simpler CI, but fragments docs/website/issues
- Git submodule — needless indirection

**Rationale:** Single source of truth for prompts (`shared/prompts/modes.json`), unified issue tracker, shared website.

**Consequences:** CI workflows must be path-filtered so Mac changes don't trigger Windows builds and vice-versa.

---

## 2026-04-18 — CI: GitHub Actions `windows-latest`

**Decision:** All builds on GHA `windows-latest` (currently Windows Server 2022).

**Rationale:** User has no Windows machine. Free for public repos.

**Consequences:** Pin to `windows-2022` explicitly before GHA rolls it forward to avoid surprise breaks.

---

## 2026-04-18 — Phase 0 gate PASSED: stack confirmed (llama-cpp-2)

**Result on `windows-latest` CI (run 24606706480, commit 561fbb9):**
- Binary: **7.18 MB** (gate: <80 MB) — 11× under budget
- Inference: **54.80 tok/s** on Qwen2.5-0.5B Q4_K_M (gate: ≥3 tok/s) — 18× over
- Output: `"Sure, I can send you the deck asap. Thank you!"` — clean EOS stop, 46 chars
- `llama-cpp-2 = "0.1.143"` with new `LlamaSampler` API

**Decision:** keep Tauri 2 + Rust + `llama-cpp-2`. No fallback to `mistral.rs` or `candle` needed.

**Notes for future phases:**
- Gemma 3 on HF is license-gated (401 without token). Production model-download UX (Phase 5) must integrate HF token + license acceptance. CI gate uses non-gated Qwen2.5-0.5B instead.
- `llama-cpp-2` caret ranges are dangerous — pinning `=0.1.54` resolved to 0.1.143 of `llama-cpp-sys-2` with incompatible bindings. Pin **both** crates explicitly at each version upgrade.
- Deprecated APIs in 0.1.143 (`token_to_str`, `Special::Tokenize`) still work but trip `-D warnings`; PoC uses `#![allow(deprecated)]`. Migrate to `token_to_piece` in Phase 3.

---

## Pending decisions (fill in as reached)


- **Hotkey default:** Ctrl+Alt+R vs alternative if conflict detected in onboarding
- **Code signing:** Certum Open-Source cert (~$70/yr) — purchased when? target: after 100 downloads
- **Microsoft Store:** MSIX submission — target v0.3
- **ARM64 build:** target v0.2
