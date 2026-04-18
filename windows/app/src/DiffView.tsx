import { useMemo } from "react";
import { Span, wordDiff } from "./diff";

interface Props {
  before: string;
  after: string;
  streaming: boolean;
}

export default function DiffView({ before, after, streaming }: Props) {
  const spans = useMemo<Span[]>(
    () => (after ? wordDiff(before, after) : []),
    [before, after]
  );

  return (
    <div
      style={{
        fontFamily: "ui-sans-serif, system-ui, sans-serif",
        fontSize: 14,
        lineHeight: 1.55,
        whiteSpace: "pre-wrap",
        wordBreak: "break-word",
      }}
    >
      {spans.length === 0 && !streaming && (
        <span style={{ color: "#9ca3af" }}>Preparing…</span>
      )}
      {spans.map((s, i) => {
        if (s.kind === "equal") return <span key={i}>{s.text}</span>;
        if (s.kind === "add")
          return (
            <span
              key={i}
              style={{
                backgroundColor: "rgba(34, 197, 94, 0.22)",
                borderRadius: 3,
                padding: "0 2px",
              }}
            >
              {s.text}
            </span>
          );
        return (
          <span
            key={i}
            style={{
              textDecoration: "line-through",
              color: "#ef4444",
              opacity: 0.7,
            }}
          >
            {s.text}
          </span>
        );
      })}
      {streaming && <span style={{ opacity: 0.4 }}>▍</span>}
    </div>
  );
}
