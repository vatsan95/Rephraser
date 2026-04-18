//! Foreground-app detection → tone hint (mirrors Mac's SourceAppTracker).
//!
//! Phase 2 scope: return the process name of the currently focused window so
//! Phase 3 can map it to a default rephrase mode.

#[cfg(windows)]
pub fn foreground_process_name() -> Option<String> {
    use windows::Win32::Foundation::{CloseHandle, MAX_PATH};
    use windows::Win32::System::ProcessStatus::GetModuleBaseNameW;
    use windows::Win32::System::Threading::{
        OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION, PROCESS_VM_READ,
    };
    use windows::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId};

    unsafe {
        let hwnd = GetForegroundWindow();
        if hwnd.0.is_null() {
            return None;
        }

        let mut pid: u32 = 0;
        GetWindowThreadProcessId(hwnd, Some(&mut pid));
        if pid == 0 {
            return None;
        }

        let handle =
            OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ, false, pid).ok()?;

        let mut buf = [0u16; MAX_PATH as usize];
        let len = GetModuleBaseNameW(handle, None, &mut buf);
        let _ = CloseHandle(handle);

        if len == 0 {
            return None;
        }
        Some(String::from_utf16_lossy(&buf[..len as usize]))
    }
}

#[cfg(not(windows))]
pub fn foreground_process_name() -> Option<String> {
    None
}

/// Map a process name to a default rephrase mode for the Phase 3 inference service.
/// Mirrors the Mac bundle-ID mapping but on exe name.
pub fn mode_for_process(name: &str) -> &'static str {
    let lower = name.to_lowercase();
    match lower.as_str() {
        "slack.exe" | "discord.exe" | "teams.exe" | "telegram.exe" => "casual",
        "outlook.exe" | "winword.exe" | "hxmail.exe" => "professional",
        "code.exe" | "devenv.exe" | "idea64.exe" | "pycharm64.exe" | "rider64.exe" => "concise",
        _ => "professional",
    }
}
