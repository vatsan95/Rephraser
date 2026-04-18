// Model manager — list catalog entries, show install state, kick off
// downloads, report streaming progress, allow deletion.
//
// Surfaces the Phase 5 commands from lib.rs:
//   - list_catalog, list_installed_models
//   - download_model → emits `download://progress` with {id, pct}
//   - delete_model

import { useCallback, useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";

interface CatalogEntry {
  id: string;
  displayName: string;
  description: string;
  repo: string;
  filename: string;
  approxSizeMB: number;
  minRamGB: number;
  promptFormat: string;
  gated: boolean;
}

interface Catalog {
  version: number;
  defaultModelId: string;
  models: CatalogEntry[];
}

interface InstalledModel {
  id: string;
  path: string;
  size_bytes: number;
}

interface Progress {
  id: string;
  downloaded: number;
  total: number;
  pct: number;
}

export default function ModelManager() {
  const [catalog, setCatalog] = useState<Catalog | null>(null);
  const [installed, setInstalled] = useState<InstalledModel[]>([]);
  const [progress, setProgress] = useState<Record<string, number>>({});
  const [busy, setBusy] = useState<Record<string, boolean>>({});
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    const installedList = await invoke<InstalledModel[]>(
      "list_installed_models"
    );
    setInstalled(installedList);
  }, []);

  useEffect(() => {
    void (async () => {
      setCatalog(await invoke<Catalog>("list_catalog"));
      await refresh();
    })();
  }, [refresh]);

  useEffect(() => {
    let unlisten: UnlistenFn | null = null;
    (async () => {
      unlisten = await listen<Progress>("download://progress", (evt) => {
        setProgress((p) => ({ ...p, [evt.payload.id]: evt.payload.pct }));
      });
    })();
    return () => {
      if (unlisten) unlisten();
    };
  }, []);

  const handleDownload = useCallback(
    async (id: string) => {
      setBusy((b) => ({ ...b, [id]: true }));
      setError(null);
      try {
        await invoke<string>("download_model", { id });
        await refresh();
      } catch (e: any) {
        setError(String(e));
      } finally {
        setBusy((b) => ({ ...b, [id]: false }));
        setProgress((p) => {
          const n = { ...p };
          delete n[id];
          return n;
        });
      }
    },
    [refresh]
  );

  const handleDelete = useCallback(
    async (id: string) => {
      if (!confirm("Delete this model from disk?")) return;
      try {
        await invoke("delete_model", { id });
        await refresh();
      } catch (e: any) {
        setError(String(e));
      }
    },
    [refresh]
  );

  if (!catalog) return <div style={{ padding: 16 }}>Loading catalog…</div>;

  const installedIds = new Set(installed.map((m) => m.id));

  return (
    <div style={{ padding: 16, maxWidth: 720 }}>
      <h2 style={{ margin: 0, fontSize: 18 }}>Models</h2>
      <p style={{ color: "#6b7280", fontSize: 13, marginTop: 4 }}>
        Downloads go to <code>%LOCALAPPDATA%\Rephraser\models\</code>. Everything
        runs locally — no data leaves your machine.
      </p>
      {error && (
        <div
          style={{
            marginTop: 8,
            padding: 8,
            color: "#b91c1c",
            backgroundColor: "#fee2e2",
            borderRadius: 6,
            fontSize: 13,
          }}
        >
          {error}
        </div>
      )}
      <ul style={{ listStyle: "none", padding: 0, marginTop: 12 }}>
        {catalog.models.map((m) => {
          const isInstalled = installedIds.has(m.id);
          const pct = progress[m.id];
          const isBusy = busy[m.id];
          return (
            <li
              key={m.id}
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "12px 14px",
                border: "1px solid #e5e7eb",
                borderRadius: 8,
                marginBottom: 8,
                gap: 12,
              }}
            >
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>
                  {m.displayName}
                  {m.gated && (
                    <span
                      style={{
                        marginLeft: 8,
                        fontSize: 11,
                        color: "#a16207",
                        backgroundColor: "#fef3c7",
                        borderRadius: 4,
                        padding: "2px 6px",
                      }}
                    >
                      gated
                    </span>
                  )}
                </div>
                <div style={{ color: "#4b5563", fontSize: 12, marginTop: 2 }}>
                  {m.description}
                </div>
                <div
                  style={{
                    color: "#9ca3af",
                    fontSize: 11,
                    marginTop: 4,
                  }}
                >
                  ~{m.approxSizeMB} MB · needs {m.minRamGB} GB RAM
                </div>
                {isBusy && pct !== undefined && (
                  <div
                    style={{
                      marginTop: 8,
                      height: 4,
                      backgroundColor: "#e5e7eb",
                      borderRadius: 2,
                      overflow: "hidden",
                    }}
                  >
                    <div
                      style={{
                        height: "100%",
                        width: `${Math.max(0, Math.min(100, pct))}%`,
                        backgroundColor: "#2563eb",
                        transition: "width 100ms linear",
                      }}
                    />
                  </div>
                )}
              </div>
              <div>
                {isInstalled ? (
                  <button
                    onClick={() => handleDelete(m.id)}
                    style={btnStyle("#fee2e2", "#b91c1c")}
                  >
                    Delete
                  </button>
                ) : (
                  <button
                    onClick={() => handleDownload(m.id)}
                    disabled={!!isBusy}
                    style={btnStyle("#2563eb", "white")}
                  >
                    {isBusy
                      ? pct !== undefined
                        ? `${Math.round(pct)}%`
                        : "…"
                      : "Download"}
                  </button>
                )}
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function btnStyle(bg: string, fg: string) {
  return {
    backgroundColor: bg,
    color: fg,
    border: "none",
    borderRadius: 6,
    padding: "6px 14px",
    fontSize: 13,
    fontWeight: 500 as const,
    cursor: "pointer",
    minWidth: 84,
  };
}
