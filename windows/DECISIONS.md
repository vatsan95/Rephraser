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

## 2026-04-18 — Phase 7: cargo-deny + VirusTotal, updater signing deferred

**Context:** Phase 7 plan calls for signing (MSI code-sign + Tauri updater
signing), VirusTotal scan, license gates. No code-signing cert purchased
yet, and no `TAURI_SIGNING_PRIVATE_KEY` generated. We do not want to block
Phase 7 on those purchases.

**Decision:**
- Ship Phase 7 with `cargo-deny` license + advisory + source gate via
  `windows/app/src-tauri/deny.toml`.
- VirusTotal scan wired into `windows-build.yml` but conditional on
  `secrets.VT_API_KEY`; fails soft (`continue-on-error`) so forks still build.
- `tauri-plugin-updater` wiring deferred until `TAURI_SIGNING_PRIVATE_KEY`
  is generated and added as a GH Actions secret. `docs/windows/latest.json`
  is shipped as a stub so the feed URL is reserved.
- MSI code-signing (Certum $70/yr) deferred per plan — revisit after the
  first 100 downloads (SmartScreen reputation argument evaporates once the
  binary is signed by any OV cert).
- `rust-toolchain.toml` pins `stable` so CI + local dev agree.

**Consequences:**
- v0.1 ships unsigned → SmartScreen "Unknown publisher" warning. Documented
  on `docs/windows.html` with screenshots (Phase 9).
- `cargo-deny` allow-list is tight (no GPL, no unmaintained); adding a new
  crate may require a deny.toml update.
- `multiple-versions = "allow"` because Tauri and llama.cpp each pull a
  different `windows-sys` major. Revisit when both upgrade.

---

## Pending decisions (fill in as reached)


- **Hotkey default:** Ctrl+Alt+R vs alternative if conflict detected in onboarding
- **Code signing:** Certum Open-Source cert (~$70/yr) — purchased when? target: after 100 downloads
- **Microsoft Store:** MSIX submission — target v0.3
- **ARM64 build:** target v0.2

---

## 2026-04-19 — Phase 7.5: hardening pass (audit remediation)

**Context:** Product + engineering audit of phases 0–9 against the plan
surfaced six concrete code gaps. Closed in commit `d81f0d9`.

**Decision:**
- **E1 (WebView2):** `tauri.conf.json` sets
  `webviewInstallMode = downloadBootstrapper` so Windows 10 <1803 auto-
  installs Edge WebView2 at setup. Adds ~2 MB to the installer; avoids a
  whole class of "blank window" bug reports.
- **E11 (cancel):** `inference.rs` checks a process-wide `AtomicBool`
  every token; `panel_dismiss` and a new `cancel_rephrase` command flip
  it. Escape mid-stream no longer lets a partial result clobber the
  clipboard on the way out.
- **A17 (long text):** reject > 6000 chars up front with a specific
  error instead of silently truncating and producing a ctx-overflow.
- **A18 (empty selection):** hotkey pressed with nothing selected now
  emits `hotkey://no-selection` instead of opening an empty panel.
- **A7 (resumable download):** `models.rs` sends `Range: bytes=<existing>-`
  when a `.part` file is present; falls back to full restart if HF
  responds 200 instead of 206. Big-model / flaky-wifi case no longer
  starts from zero.
- **A11 (RAM warn):** `GlobalMemoryStatusEx` (via the existing `windows`
  crate, new feature `Win32_System_SystemInformation`) compares total
  physical RAM against the catalog's `minRamGB`; emits
  `download://low-ram` as a non-blocking signal. Not a hard block — swap
  exists, and the catalog value is conservative.

**Consequences:**
- Zero new dependencies (reused the `windows` crate for RAM probe).
- Frontend work queued for Phase 8: toast listeners for
  `hotkey://no-selection` and `download://low-ram`, plus wiring
  `cancel_rephrase` to Escape / mode-change mid-stream.
- SHA-per-file model verification remains deferred (E14) — bartowski
  doesn't publish canonical hashes per release; revisit when the catalog
  carries digests.

