// Word-level LCS diff. Matches the Mac app's `DiffView.swift` behaviour: we
// show words added/removed against the original selection so the user can
// eyeball the change before hitting Enter.
//
// O(n·m) dynamic-programming LCS; fine for rephrase-sized text (up to a
// few thousand words). If inputs ever exceed that, swap to Myers diff.

export type Span =
  | { kind: "equal"; text: string }
  | { kind: "add"; text: string }
  | { kind: "remove"; text: string };

function tokenize(input: string): string[] {
  // Keep whitespace as its own token so we can reconstruct the string.
  return input.match(/\s+|[^\s]+/g) ?? [];
}

export function wordDiff(before: string, after: string): Span[] {
  const a = tokenize(before);
  const b = tokenize(after);
  const n = a.length;
  const m = b.length;
  const dp: number[][] = Array.from({ length: n + 1 }, () =>
    new Array(m + 1).fill(0)
  );
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  const spans: Span[] = [];
  let i = 0;
  let j = 0;
  const push = (s: Span) => {
    const last = spans[spans.length - 1];
    if (last && last.kind === s.kind) last.text += s.text;
    else spans.push(s);
  };
  while (i < n && j < m) {
    if (a[i] === b[j]) {
      push({ kind: "equal", text: a[i] });
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      push({ kind: "remove", text: a[i] });
      i++;
    } else {
      push({ kind: "add", text: b[j] });
      j++;
    }
  }
  while (i < n) push({ kind: "remove", text: a[i++] });
  while (j < m) push({ kind: "add", text: b[j++] });
  return spans;
}
