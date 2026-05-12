# Component Library

This file contains the complete base CSS and HTML patterns for every slide component.

## How to use this file

When generating a presentation:
1. Start with the **Page Scaffold** at the bottom of this file
2. Paste the chosen theme's `:root` block from `themes.md` at the top of `<style>`
3. Add the **Base CSS** below it
4. Build slides using the **HTML Component Patterns**
5. The **Navigation JS** and **Detail Panel JS** go at the bottom of `<body>`

---

## Base CSS

Paste this after the `:root` theme block. Do not modify — component HTML depends on these class names.

```css
/* ── RESET & BODY ── */
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body {
  width: 100%; height: 100%;
  font-family: -apple-system, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  background: var(--bg); color: var(--text); overflow: hidden;
}

/* ── DECK & SLIDES ── */
.deck { width: 100%; height: 100vh; position: relative; }
.slide {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; justify-content: center; align-items: center;
  padding: 48px 80px;
  opacity: 0; pointer-events: none; transition: opacity .4s ease;
}
.slide.active { opacity: 1; pointer-events: auto; }
.slide-inner { width: 100%; max-width: 1100px; }

/* ── NAVIGATION BAR ── */
.nav {
  position: fixed; bottom: 28px; left: 50%; transform: translateX(-50%);
  display: flex; align-items: center; gap: 16px; z-index: 200;
  background: var(--nav-bg); border: 1px solid var(--border);
  backdrop-filter: blur(10px); padding: 10px 20px; border-radius: 40px;
}
.nav button {
  background: none; border: none; color: var(--text-muted);
  font-size: 18px; cursor: pointer; padding: 4px 8px; border-radius: 6px;
  transition: color .2s, background .2s;
}
.nav button:hover { color: var(--accent); background: var(--surface2); }
.nav button:disabled { opacity: .25; cursor: default; }
.nav .counter { font-size: 13px; color: var(--text-muted); min-width: 52px; text-align: center; }
.dots { display: flex; gap: 6px; }
.dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: var(--text-dim); cursor: pointer;
  transition: background .2s, transform .2s;
}
.dot.active { background: var(--accent); transform: scale(1.3); }
.kbd-hint { position: fixed; top: 20px; right: 28px; font-size: 11px; color: var(--text-dim); letter-spacing: .5px; z-index: 100; }

/* ── TYPOGRAPHY ── */
.label {
  font-size: 11px; letter-spacing: 2px; text-transform: uppercase;
  color: var(--text-muted); margin-bottom: 16px;
  display: flex; align-items: center; gap: 8px;
}
.label::before { content: ''; display: block; width: 24px; height: 1px; background: var(--text-dim); }
h1 { font-size: clamp(32px,4vw,52px); font-weight: 700; line-height: 1.1; letter-spacing: -1px; }
h2 { font-size: clamp(20px,2.6vw,34px); font-weight: 600; line-height: 1.2; margin-bottom: 22px; }
h3 { font-size: 15px; font-weight: 600; color: var(--accent); margin-bottom: 8px; }
p, li { font-size: 15px; line-height: 1.7; color: var(--text-muted); }
code {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 12px; background: var(--surface2); color: var(--accent4);
  padding: 2px 6px; border-radius: 4px;
}

/* ── GRIDS ── */
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; width: 100%; max-width: 1100px; }
.grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 18px; width: 100%; max-width: 1100px; }

/* ── CARDS ── */
.card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
.card.accent-blue   { border-color: var(--tint-blue-border);   background: var(--tint-blue); }
.card.accent-green  { border-color: var(--tint-green-border);  background: var(--tint-green); }
.card.accent-orange { border-color: var(--tint-orange-border); background: var(--tint-orange); }
.card.accent-purple { border-color: var(--tint-purple-border); background: var(--tint-purple); }
.card h3 { font-size: 14px; color: var(--text); margin-bottom: 8px; }
.card p, .card li { font-size: 13px; color: var(--text-muted); line-height: 1.6; }
.card ul { padding-left: 16px; }
.card ul li { margin-bottom: 4px; }

/* Phase cards (clickable) */
.phase-card { cursor: pointer; transition: border-color .2s, transform .15s; position: relative; }
.phase-card:hover { transform: translateY(-2px); }
.phase-card.blue:hover   { border-color: var(--accent); }
.phase-card.green:hover  { border-color: var(--accent2); }
.phase-card.orange:hover { border-color: var(--accent3); }
.phase-card.purple:hover { border-color: var(--accent4); }

/* ── FLOW STEPS ── */
.flow { display: flex; align-items: stretch; gap: 0; width: 100%; max-width: 1100px; flex-wrap: nowrap; margin-bottom: 16px; }
.flow-step {
  flex: 1; background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: 16px 12px; text-align: center;
  min-width: 0; cursor: pointer; position: relative;
  transition: border-color .2s, background .2s, transform .15s;
}
.flow-step:hover { border-color: var(--accent); background: var(--tint-blue); transform: translateY(-2px); }
.flow-step.gate { border-color: var(--tint-orange-border); background: var(--tint-orange); }
.flow-step.gate:hover { border-color: var(--accent3); }
.flow-step .num  { font-size: 10px; color: var(--accent); letter-spacing: 1px; margin-bottom: 5px; }
.flow-step.gate .num { color: var(--accent3); }
.flow-step .title { font-size: 12px; font-weight: 600; color: var(--text); margin-bottom: 3px; }
.flow-step .desc  { font-size: 10px; color: var(--text-muted); line-height: 1.4; }
.flow-arrow { color: var(--text-dim); font-size: 16px; padding: 0 6px; flex-shrink: 0; display: flex; align-items: center; }
.expand-hint { position: absolute; bottom: 6px; right: 8px; font-size: 9px; color: var(--text-dim); letter-spacing: .5px; }
.flow-step:hover .expand-hint { color: var(--accent); }

/* ── TIMELINE ── */
.timeline { width: 100%; max-width: 1000px; }
.tl-item { display: flex; gap: 18px; margin-bottom: 14px; align-items: flex-start; }
.tl-left { text-align: right; min-width: 72px; padding-top: 3px; }
.tl-round { font-size: 10px; font-weight: 700; color: var(--accent); letter-spacing: 1px; }
.tl-dot-wrap { display: flex; flex-direction: column; align-items: center; }
.tl-dot { width: 10px; height: 10px; border-radius: 50%; background: var(--accent); flex-shrink: 0; margin-top: 4px; }
.tl-dot.green  { background: var(--accent2); }
.tl-dot.orange { background: var(--accent3); }
.tl-dot.purple { background: var(--accent4); }
.tl-line { width: 1px; flex: 1; background: var(--border); min-height: 20px; }
.tl-content {
  flex: 1; cursor: pointer; background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: 10px 14px;
  transition: border-color .2s, background .2s;
}
.tl-content:hover { border-color: var(--accent); background: var(--tint-blue); }
.tl-title { font-size: 13px; font-weight: 600; color: var(--text); margin-bottom: 3px; display: flex; justify-content: space-between; align-items: center; }
.tl-desc  { font-size: 11px; color: var(--text-muted); }
.tl-badge { display: inline-block; font-size: 10px; padding: 2px 7px; border-radius: 4px; background: var(--tint-green); color: var(--accent2); margin-left: 8px; }
.tl-badge.orange { background: var(--tint-orange); color: var(--accent3); }
.tl-arrow { font-size: 11px; color: var(--text-dim); flex-shrink: 0; }
.tl-content:hover .tl-arrow { color: var(--accent); }

/* ── PERFORMANCE BARS ── */
.perf-row { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.perf-label { font-size: 11px; color: var(--text-muted); min-width: 130px; text-align: right; }
.perf-bar-wrap { flex: 1; height: 20px; background: var(--surface2); border-radius: 4px; overflow: hidden; }
.perf-bar { height: 100%; border-radius: 4px; display: flex; align-items: center; padding-left: 8px; font-size: 10px; font-weight: 700; font-family: monospace; white-space: nowrap; color: #fff; }
.perf-bar.red    { background: var(--bar-red); }
.perf-bar.yellow { background: var(--bar-yellow); }
.perf-bar.green  { background: var(--bar-green); }

/* ── STATS WIDGETS ── */
.stats { display: flex; gap: 16px; }
.stat { background: var(--surface2); border: 1px solid var(--border); border-radius: 10px; padding: 14px 18px; text-align: center; flex: 1; }
.stat .val { font-size: 28px; font-weight: 700; font-family: monospace; color: var(--accent); }
.stat .val.green  { color: var(--accent2); }
.stat .val.purple { color: var(--accent4); }
.stat .unit { font-size: 11px; color: var(--text-dim); margin-top: 2px; }

/* ── TABLES ── */
table { width: 100%; border-collapse: collapse; font-size: 12px; }
th { background: var(--surface2); color: var(--text-muted); font-weight: 600; font-size: 10px; letter-spacing: 1px; text-transform: uppercase; padding: 9px 12px; text-align: left; border-bottom: 1px solid var(--border); }
td { padding: 9px 12px; border-bottom: 1px solid var(--border); color: var(--text-muted); }
tr:last-child td { border-bottom: none; }
.cell-ok { color: var(--accent2); font-weight: 600; }

/* ── COVER SLIDE ── */
.cover { text-align: center; }
.kicker { display: inline-flex; align-items: center; gap: 8px; font-size: 12px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--accent); border: 1px solid var(--tint-blue-border); background: var(--tint-blue); padding: 6px 16px; border-radius: 20px; margin-bottom: 32px; }
.cover h1 { max-width: 820px; margin: 0 auto 20px; }
.cover h1 span { color: var(--accent); }
.cover .sub { color: var(--text-muted); font-size: 15px; margin-bottom: 48px; }
.cover .tags { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }
.tag { font-size: 12px; padding: 5px 14px; border-radius: 20px; border: 1px solid var(--border); color: var(--text-muted); }
.tag.green  { border-color: var(--tint-green-border);  color: var(--accent2); background: var(--tint-green); }
.tag.blue   { border-color: var(--tint-blue-border);   color: var(--accent);  background: var(--tint-blue); }
.tag.purple { border-color: var(--tint-purple-border); color: var(--accent4); background: var(--tint-purple); }

/* ── BANNER ── */
.banner {
  width: 100%; max-width: 1100px; border-radius: 10px; padding: 12px 18px;
  display: flex; align-items: center; gap: 12px; margin-top: 14px;
  font-size: 12px; color: var(--text-muted);
  background: var(--banner-bg); border: 1px solid var(--banner-border);
}

/* ── CONCLUSION SLIDE ── */
.conclusion-wrap { width: 100%; max-width: 900px; text-align: center; }
.big-stat {
  font-size: 80px; font-weight: 800; font-family: monospace;
  background: linear-gradient(135deg, var(--accent2), var(--accent));
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  line-height: 1; margin: 24px 0 8px;
}
.quote { font-size: 15px; color: var(--text-muted); max-width: 680px; margin: 0 auto 28px; line-height: 1.7; font-style: italic; }
.sep { width: 40px; height: 2px; background: var(--accent); border-radius: 2px; margin: 16px auto; }
.pill { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; padding: 4px 12px; border-radius: 20px; border: 1px solid var(--tint-blue-border); color: var(--accent); background: var(--tint-blue); margin: 3px; }
.pill.green  { border-color: var(--tint-green-border);  color: var(--accent2); background: var(--tint-green); }
.pill.purple { border-color: var(--tint-purple-border); color: var(--accent4); background: var(--tint-purple); }

/* ── DETAIL PANEL ── */
.detail-overlay { position: fixed; inset: 0; z-index: 300; pointer-events: none; }
.detail-overlay.open { pointer-events: auto; }
.detail-backdrop { position: absolute; inset: 0; background: rgba(0,0,0,.45); opacity: 0; transition: opacity .3s ease; }
.detail-overlay.open .detail-backdrop { opacity: 1; }
.detail-panel {
  position: absolute; top: 0; right: 0; width: 480px; height: 100%;
  background: var(--detail-bg); border-left: 1px solid var(--border);
  display: flex; flex-direction: column;
  transform: translateX(100%); transition: transform .32s cubic-bezier(.22,1,.36,1);
  box-shadow: -8px 0 40px rgba(0,0,0,.4);
}
.detail-overlay.open .detail-panel { transform: translateX(0); }
.detail-head { padding: 20px 22px 16px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: flex-start; flex-shrink: 0; }
.detail-head-title { font-size: 13px; font-weight: 700; color: var(--text); line-height: 1.3; }
.detail-head-sub { font-size: 11px; color: var(--text-muted); margin-top: 3px; }
.detail-close { background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer; padding: 4px; border-radius: 6px; line-height: 1; flex-shrink: 0; transition: color .2s, background .2s; }
.detail-close:hover { color: var(--text); background: var(--surface2); }
.detail-body { flex: 1; overflow-y: auto; padding: 20px 22px; }
.detail-body::-webkit-scrollbar { width: 4px; }
.detail-body::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }

/* Detail body content */
.d-section { margin-bottom: 20px; }
.d-section:last-child { margin-bottom: 0; }
.d-title { font-size: 11px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--text-muted); margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
.d-row { display: flex; gap: 10px; padding: 8px 0; border-bottom: 1px solid var(--border); align-items: flex-start; }
.d-row:last-child { border-bottom: none; }
.d-num { flex-shrink: 0; width: 20px; height: 20px; border-radius: 50%; background: var(--surface2); border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: 700; color: var(--accent); }
.d-content { flex: 1; }
.d-name { font-size: 12px; font-weight: 600; color: var(--text); margin-bottom: 3px; }
.d-desc { font-size: 11px; color: var(--text-muted); line-height: 1.6; }
.d-trap { font-size: 10px; color: var(--accent3); background: var(--tint-orange); border: 1px solid var(--tint-orange-border); border-radius: 4px; padding: 4px 8px; margin-top: 5px; }
.d-code { font-family: 'JetBrains Mono', 'Fira Code', monospace; font-size: 11px; background: var(--code-bg); border: 1px solid var(--border); border-radius: 6px; padding: 10px 12px; margin: 8px 0; color: var(--code-text); line-height: 1.7; overflow-x: auto; white-space: pre; }
.d-check { display: flex; gap: 8px; padding: 6px 0; align-items: flex-start; }
.d-check .ck { flex-shrink: 0; color: var(--accent2); font-size: 13px; }
.d-check .ck.warn { color: var(--accent3); }
.d-check p { font-size: 12px; line-height: 1.5; }
.d-badge { display: inline-block; font-size: 10px; padding: 2px 7px; border-radius: 4px; margin: 2px; }
.d-badge.blue   { background: var(--tint-blue);   color: var(--accent); }
.d-badge.green  { background: var(--tint-green);  color: var(--accent2); }
.d-badge.orange { background: var(--tint-orange); color: var(--accent3); }
.d-badge.purple { background: var(--tint-purple); color: var(--accent4); }
.d-formula { background: var(--surface2); border-radius: 6px; padding: 10px 14px; font-family: monospace; font-size: 11px; color: var(--accent4); line-height: 1.8; margin: 8px 0; }
.d-table { width: 100%; border-collapse: collapse; font-size: 11px; margin: 6px 0; }
.d-table th { background: var(--surface2); color: var(--text-muted); padding: 6px 10px; text-align: left; border-bottom: 1px solid var(--border); font-size: 10px; letter-spacing: .5px; }
.d-table td { padding: 6px 10px; border-bottom: 1px solid var(--border); color: var(--text-muted); }
.d-table tr:last-child td { border-bottom: none; }
```

---

## HTML Component Patterns

### Cover Slide

```html
<div class="slide active cover">
  <div class="kicker">🧪 Experiment · ProjectName</div>
  <h1>Feature / Initiative <span>Key Word</span><br>Subtitle Line</h1>
  <p class="sub">One sentence describing what this deck covers</p>
  <div class="tags">
    <span class="tag blue">Component A</span>
    <span class="tag purple">Component B</span>
    <span class="tag green">Result / Outcome</span>
    <span class="tag">Platform / Context</span>
  </div>
</div>
```

### Problem / Background Slide

```html
<div class="slide">
  <div class="slide-inner">
    <div class="label">Background</div>
    <h2>Why Is This Hard?</h2>
    <div class="grid-2">
      <div>
        <div class="card accent-orange">
          <div style="font-size:28px;margin-bottom:10px">🔗</div>
          <h3>Challenge One</h3>
          <ul><li>Detail A</li><li>Detail B</li></ul>
        </div>
        <div class="card" style="margin-top:14px">
          <div style="font-size:28px;margin-bottom:10px">🔄</div>
          <h3>Challenge Two</h3>
          <ul><li>Detail A</li><li>Detail B</li></ul>
        </div>
      </div>
      <div style="display:flex;flex-direction:column;gap:14px">
        <div class="card accent-blue">
          <div style="font-size:28px;margin-bottom:10px">💡</div>
          <h3>Core Proposition</h3>
          <p style="font-size:14px;color:var(--text);line-height:1.8">
            Can we <strong style="color:var(--accent)">do X → Y → Z</strong> automatically?
          </p>
        </div>
        <div class="card accent-green">
          <div style="font-size:28px;margin-bottom:10px">🎯</div>
          <h3>Approach</h3>
          <ul><li>Mechanism A</li><li>Mechanism B</li><li>Sample / Proof point</li></ul>
        </div>
      </div>
    </div>
  </div>
</div>
```

### 3-Column Architecture Slide (clickable cards)

```html
<div class="slide">
  <div class="slide-inner">
    <div class="label">System Design</div>
    <h2>Three Core Components</h2>
    <div class="grid-3">
      <div class="card accent-blue phase-card blue" onclick="openDetail('comp-a')">
        <div style="font-size:28px;margin-bottom:10px">🔧</div>
        <h3 style="color:var(--accent)">Component A</h3>
        <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px">Subtitle / tech stack</p>
        <ul><li><code>api_call_1()</code></li><li><code>api_call_2()</code></li></ul>
        <div class="expand-hint">Click for details →</div>
      </div>
      <div class="card accent-green phase-card green" onclick="openDetail('comp-b')">
        <div style="font-size:28px;margin-bottom:10px">📋</div>
        <h3 style="color:var(--accent2)">Component B</h3>
        <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px">Subtitle</p>
        <ul><li>Feature 1</li><li>Feature 2</li></ul>
        <div class="expand-hint">Click for details →</div>
      </div>
      <div class="card accent-purple phase-card purple" onclick="openDetail('comp-c')">
        <div style="font-size:28px;margin-bottom:10px">📊</div>
        <h3 style="color:var(--accent4)">Component C</h3>
        <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px">Subtitle</p>
        <ul><li>Feature 1</li><li>Feature 2</li></ul>
        <div class="expand-hint">Click for details →</div>
      </div>
    </div>
  </div>
</div>
```

### Workflow / Pipeline Slide (flow steps)

```html
<div class="slide">
  <div class="slide-inner">
    <div class="label">Workflow</div>
    <h2>6-Step Process <span style="font-size:13px;color:var(--text-dim);font-weight:400">· Click a step for details</span></h2>
    <div class="flow">
      <div class="flow-step" onclick="openDetail('step1')">
        <div class="num">STEP 1</div>
        <div class="title">Analysis</div>
        <div class="desc">Input scan<br>verification</div>
        <div class="expand-hint">↗</div>
      </div>
      <div class="flow-arrow">→</div>
      <div class="flow-step gate" onclick="openDetail('step2')">
        <div class="num">STEP 2 · Gate</div>
        <div class="title">Doc First</div>
        <div class="desc">Required before<br>any code</div>
        <div class="expand-hint">↗</div>
      </div>
      <div class="flow-arrow">→</div>
      <div class="flow-step" onclick="openDetail('step3')">
        <div class="num">STEP 3</div>
        <div class="title">Implement</div>
        <div class="desc">Layer A<br>Layer B</div>
        <div class="expand-hint">↗</div>
      </div>
      <div class="flow-arrow">→</div>
      <div class="flow-step" onclick="openDetail('step4')">
        <div class="num">STEP 4</div>
        <div class="title">Build + Test</div>
        <div class="desc">Compile → UT<br>E2E → verify</div>
        <div class="expand-hint">↗</div>
      </div>
      <div class="flow-arrow">→</div>
      <div class="flow-step" onclick="openDetail('step5')">
        <div class="num">STEP 5</div>
        <div class="title">Optimize</div>
        <div class="desc">Profiling<br>ratio &lt; 1.0</div>
        <div class="expand-hint">↗</div>
      </div>
      <div class="flow-arrow">→</div>
      <div class="flow-step" onclick="openDetail('step6')">
        <div class="num">STEP 6</div>
        <div class="title">Deliver</div>
        <div class="desc">Archive<br>report</div>
        <div class="expand-hint">↗</div>
      </div>
    </div>
    <div class="banner">
      <span style="font-size:18px;flex-shrink:0">🔒</span>
      <span><strong style="color:var(--accent4)">Design principle:</strong> Gate steps enforce documentation before implementation — preventing skip-ahead is the core constraint of this workflow.</span>
    </div>
  </div>
</div>
```

### Timeline Slide

```html
<div class="slide">
  <div style="width:100%;max-width:980px">
    <div class="label">Iteration History</div>
    <h2>N Rounds of Self-Iteration <span style="font-size:13px;color:var(--text-dim);font-weight:400">· Click for details</span></h2>
    <div class="timeline">

      <div class="tl-item">
        <div class="tl-left"><span class="tl-round">A</span></div>
        <div class="tl-dot-wrap"><div class="tl-dot"></div><div class="tl-line"></div></div>
        <div class="tl-content" onclick="openDetail('tlA')">
          <div class="tl-title">Round A title <span class="tl-arrow">›</span></div>
          <div class="tl-desc">Short description of what changed in this round</div>
        </div>
      </div>

      <div class="tl-item">
        <div class="tl-left"><span class="tl-round">B</span></div>
        <div class="tl-dot-wrap"><div class="tl-dot green"></div><div class="tl-line"></div></div>
        <div class="tl-content" onclick="openDetail('tlB')">
          <div class="tl-title">Round B title <span class="tl-badge">Tag</span> <span class="tl-arrow">›</span></div>
          <div class="tl-desc">Description</div>
        </div>
      </div>

      <div class="tl-item">
        <div class="tl-left"><span class="tl-round">C</span></div>
        <div class="tl-dot-wrap"><div class="tl-dot orange"></div></div>
        <div class="tl-content" onclick="openDetail('tlC')">
          <div class="tl-title">Round C title <span class="tl-badge orange">Issue Found</span> <span class="tl-arrow">›</span></div>
          <div class="tl-desc">Description</div>
        </div>
      </div>

    </div>
  </div>
</div>
```

### Performance Results Slide

```html
<div class="slide">
  <div class="slide-inner">
    <div class="label">Results · Performance</div>
    <h2>All Scenarios Reached Target ratio &lt; 1.0</h2>
    <div class="grid-2" style="align-items:start">
      <div>
        <h3 style="margin-bottom:12px;font-size:12px;color:var(--text-muted)">Scenario A (description)</h3>
        <div class="perf-row">
          <span class="perf-label">Baseline</span>
          <div class="perf-bar-wrap"><div class="perf-bar red" style="width:100%">ratio 3.2</div></div>
        </div>
        <div class="perf-row">
          <span class="perf-label">Opt 1 · Change</span>
          <div class="perf-bar-wrap"><div class="perf-bar yellow" style="width:50%">1.53</div></div>
          <span style="font-size:10px;color:var(--text-muted)">note</span>
        </div>
        <div class="perf-row">
          <span class="perf-label">Opt 2 · Change</span>
          <div class="perf-bar-wrap"><div class="perf-bar green" style="width:31%">0.99 ✅</div></div>
          <span style="font-size:10px;color:var(--text-muted)">note</span>
        </div>
      </div>
      <div>
        <div class="stats" style="flex-direction:column">
          <div class="stat"><div class="val green">0.993</div><div class="unit">Scenario A · description</div></div>
          <div class="stat"><div class="val green">0.849</div><div class="unit">Scenario B · description</div></div>
          <div class="stat"><div class="val green">0.985</div><div class="unit">Scenario C · description</div></div>
        </div>
        <div class="card" style="margin-top:14px">
          <h3>Test Environment</h3>
          <ul>
            <li>Data scale details</li>
            <li>Cluster configuration</li>
            <li>Measurement methodology</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>
```

### Conclusion Slide

```html
<div class="slide">
  <div class="conclusion-wrap">
    <div class="label" style="justify-content:center">Conclusion</div>
    <div style="display:flex;gap:24px;justify-content:center;margin:24px 0 12px">
      <div style="text-align:center">
        <div style="font-size:48px;font-weight:800;font-family:monospace;color:var(--accent2);line-height:1">0.993</div>
        <div style="font-size:11px;color:var(--text-muted);margin-top:4px">Scenario A</div>
      </div>
      <div style="text-align:center">
        <div style="font-size:48px;font-weight:800;font-family:monospace;color:var(--accent2);line-height:1">0.849</div>
        <div style="font-size:11px;color:var(--text-muted);margin-top:4px">Scenario B</div>
      </div>
    </div>
    <p style="font-size:13px;color:var(--text-dim);margin-bottom:20px">metric definition · &lt;1.0 = better · overall = N.NNN</p>
    <p class="quote">「One or two sentences summarizing what was proved or delivered, in the voice of someone explaining why it matters.」</p>
    <div style="display:flex;gap:12px;justify-content:center;flex-wrap:wrap;margin-bottom:28px">
      <span class="pill green">Key achievement 1</span>
      <span class="pill green">Key achievement 2</span>
      <span class="pill purple">Process/method highlight</span>
    </div>
    <div class="sep"></div>
    <p style="font-size:13px;color:var(--text-muted);margin-top:16px">Next steps: ...</p>
  </div>
</div>
```

### Detail Panel Content (DETAILS object entry)

Add to the `const DETAILS = { ... }` JS object:

```js
'key-name': {
  title: 'Panel Title',
  sub: 'Panel subtitle or context',
  body: `
  <div class="d-section">
    <div class="d-title">Section Heading</div>
    <div class="d-row">
      <div class="d-num">1</div>
      <div class="d-content">
        <div class="d-name">Item name</div>
        <div class="d-desc">Explanation of this item. Can be multiple sentences.</div>
        <div class="d-code">code or formula here</div>
        <div class="d-trap">⚠ Warning or pitfall note</div>
      </div>
    </div>
  </div>
  <div class="d-section">
    <div class="d-title">Checklist</div>
    <div class="d-check"><span class="ck">✓</span><p>Verified item</p></div>
    <div class="d-check"><span class="ck warn">⚠</span><p>Caution item</p></div>
  </div>`
},
```

---

## Complete Page Scaffold

Copy this template for every new deck. Replace `[THEME_CSS]` with the `:root` block + extra rules from `themes.md`, fill in slides, and populate `DETAILS`.

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Deck Title</title>
<style>
/* ── THEME ── */
[THEME_CSS]

/* ── BASE CSS ── */
[FULL BASE CSS FROM ABOVE]
</style>
</head>
<body>

<!-- ── DETAIL PANEL (global, one instance) ── -->
<div class="detail-overlay" id="detailOverlay">
  <div class="detail-backdrop" id="detailBackdrop"></div>
  <div class="detail-panel">
    <div class="detail-head">
      <div>
        <div class="detail-head-title" id="detailTitle"></div>
        <div class="detail-head-sub" id="detailSub"></div>
      </div>
      <button class="detail-close" onclick="closeDetail()">✕</button>
    </div>
    <div class="detail-body" id="detailBody"></div>
  </div>
</div>

<div class="deck" id="deck">
  <!-- ══ SLIDE 1 ══ -->
  <!-- ... slides go here ... -->
</div>

<!-- NAV -->
<div class="nav">
  <button id="prev" onclick="go(-1)" disabled>‹</button>
  <div class="dots" id="dots"></div>
  <span class="counter" id="counter"></span>
  <button id="next" onclick="go(1)">›</button>
</div>
<div class="kbd-hint">← → Space to navigate · Esc closes panel</div>

<script>
// ── SLIDE NAVIGATION ──
const slides = document.querySelectorAll('.slide');
const dotsEl = document.getElementById('dots');
const counter = document.getElementById('counter');
const prevBtn = document.getElementById('prev');
const nextBtn = document.getElementById('next');
let cur = 0;

slides.forEach((_, i) => {
  const d = document.createElement('div');
  d.className = 'dot' + (i === 0 ? ' active' : '');
  d.onclick = () => goTo(i);
  dotsEl.appendChild(d);
});
counter.textContent = `1 / ${slides.length}`;

function goTo(n) {
  slides[cur].classList.remove('active');
  dotsEl.children[cur].classList.remove('active');
  cur = Math.max(0, Math.min(n, slides.length - 1));
  slides[cur].classList.add('active');
  dotsEl.children[cur].classList.add('active');
  counter.textContent = `${cur + 1} / ${slides.length}`;
  prevBtn.disabled = cur === 0;
  nextBtn.disabled = cur === slides.length - 1;
}
function go(d) { goTo(cur + d); }

document.addEventListener('keydown', e => {
  if (detailOpen) { if (e.key === 'Escape') closeDetail(); return; }
  if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); go(1); }
  if (e.key === 'ArrowLeft') { e.preventDefault(); go(-1); }
});

// ── DETAIL PANEL ──
let detailOpen = false;
document.getElementById('detailBackdrop').addEventListener('click', closeDetail);

function openDetail(key) {
  const data = DETAILS[key];
  if (!data) return;
  document.getElementById('detailTitle').textContent = data.title;
  document.getElementById('detailSub').textContent = data.sub || '';
  document.getElementById('detailBody').innerHTML = data.body;
  document.getElementById('detailOverlay').classList.add('open');
  detailOpen = true;
}
function closeDetail() {
  document.getElementById('detailOverlay').classList.remove('open');
  detailOpen = false;
}

// ── DETAIL CONTENT ──
const DETAILS = {
  // Add entries here: 'key': { title, sub, body }
};
</script>
</body>
</html>
```
