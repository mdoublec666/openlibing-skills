# Themes

Each theme is a `:root` CSS variable block. Paste the chosen block at the top of the `<style>` tag, then add the shared base CSS and component CSS from `components.md`.

Light themes also require a few extra rules listed in their section — don't skip those.

---

## Theme 1 · Dark · GitHub

```css
:root {
  /* Backgrounds */
  --bg:       #0d1117;
  --surface:  #161b22;
  --surface2: #21262d;
  --border:   #30363d;

  /* Accents */
  --accent:  #58a6ff;   /* blue  */
  --accent2: #3fb950;   /* green */
  --accent3: #f78166;   /* coral */
  --accent4: #d2a8ff;   /* purple */

  /* Text */
  --text:       #e6edf3;
  --text-muted: #8b949e;
  --text-dim:   #484f58;

  /* UI chrome */
  --nav-bg:       rgba(22,27,34,.9);
  --detail-bg:    #161b22;
  --code-bg:      rgba(13,17,23,.8);
  --code-text:    #d2a8ff;

  /* Card accent tints */
  --tint-blue:   rgba(88,166,255,.06);
  --tint-green:  rgba(63,185,80,.06);
  --tint-orange: rgba(247,129,102,.06);
  --tint-purple: rgba(210,168,255,.06);
  --tint-blue-border:   rgba(88,166,255,.35);
  --tint-green-border:  rgba(63,185,80,.35);
  --tint-orange-border: rgba(247,129,102,.35);
  --tint-purple-border: rgba(210,168,255,.35);

  /* Banner */
  --banner-bg:     rgba(210,168,255,.07);
  --banner-border: rgba(210,168,255,.25);

  /* Perf bars */
  --bar-red:    rgba(247,129,102,.7);
  --bar-yellow: rgba(227,179,65,.7);
  --bar-green:  rgba(63,185,80,.8);
}
```

No additional overrides needed for Dark.

---

## Theme 2 · Light · 暖珊瑚

Warm cream background with coral/terracotta accents. Feels professional and approachable.

```css
:root {
  /* Backgrounds */
  --bg:       #FAF9F7;
  --surface:  #FFFFFF;
  --surface2: #F0EDE8;
  --border:   #E0D9D0;

  /* Accents — 暖珊瑚 coral palette */
  --accent:  #D97757;   /* coral/terracotta — primary */
  --accent2: #2E7D52;   /* forest green */
  --accent3: #C94B4B;   /* red/warning */
  --accent4: #7C5CBF;   /* purple */

  /* Text */
  --text:       #1A1817;
  --text-muted: #6B6560;
  --text-dim:   #A8A29E;

  /* UI chrome */
  --nav-bg:       rgba(250,249,247,.92);
  --detail-bg:    #FFFFFF;
  --code-bg:      #F0EDE8;
  --code-text:    #7C5CBF;

  /* Card accent tints */
  --tint-blue:   rgba(217,119,87,.06);
  --tint-green:  rgba(46,125,82,.07);
  --tint-orange: rgba(201,75,75,.06);
  --tint-purple: rgba(124,92,191,.06);
  --tint-blue-border:   rgba(217,119,87,.4);
  --tint-green-border:  rgba(46,125,82,.4);
  --tint-orange-border: rgba(201,75,75,.35);
  --tint-purple-border: rgba(124,92,191,.35);

  /* Banner */
  --banner-bg:     rgba(124,92,191,.07);
  --banner-border: rgba(124,92,191,.25);

  /* Perf bars */
  --bar-red:    rgba(201,75,75,.75);
  --bar-yellow: rgba(200,150,40,.75);
  --bar-green:  rgba(46,125,82,.75);
}
```

**Additional rules for Light · 暖珊瑚** — add after `:root`:

```css
/* Invert dark-specific patterns for light backgrounds */
body { color: var(--text); }

.kicker {
  border-color: rgba(217,119,87,.35);
  background: rgba(217,119,87,.08);
  color: var(--accent);
}

.cover h1 span { color: var(--accent); }

h3 { color: var(--accent); }

code {
  background: var(--surface2);
  color: var(--code-text);
}

.detail-panel {
  background: var(--detail-bg);
  box-shadow: -6px 0 32px rgba(0,0,0,.12);
}

.d-code {
  background: var(--code-bg);
  color: var(--code-text);
  border-color: var(--border);
}

/* Stat values */
.stat .val { color: var(--accent); }
.stat .val.green { color: var(--accent2); }

/* Cover gradient quote on conclusion */
.big-stat {
  background: linear-gradient(135deg, var(--accent2), var(--accent));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

---

## How Theme Variables Map to Components

| Variable | Used By |
|----------|---------|
| `--bg` | `body` background, code block background |
| `--surface` | Cards, detail panel, timeline items |
| `--surface2` | Stat boxes, nav button hover, table headers |
| `--border` | All borders, table dividers |
| `--accent` | Primary highlights, links, dot indicators, h3 |
| `--accent2` | Success / positive values (green) |
| `--accent3` | Warnings, gate steps, negative values (red/orange) |
| `--accent4` | Secondary highlights, code text, purple labels |
| `--text` | Primary body text |
| `--text-muted` | Secondary text, descriptions, `<p>`, `<li>` |
| `--text-dim` | Tertiary text, placeholders, keyboard hint |
| `--tint-*` / `--tint-*-border` | `.card.accent-*` background + border tints |
| `--nav-bg` | Navigation bar background |
| `--detail-bg` | Detail panel background |
| `--code-bg` / `--code-text` | `code` and `.d-code` blocks |
| `--bar-red/yellow/green` | Performance bar fill colors |
| `--banner-bg/border` | Bottom banner component |
