---
name: flaticon-downloader
description: Search, select, and download icons from Flaticon for PPT and design projects. Use Claude's WebSearch tool to find icons, then download them directly from CDN. Supports batch download with style consistency. Use this skill when the user needs to find and download icons, especially for presentations.
---

# Flaticon Icon Downloader

Download icons from Flaticon for presentations and design projects using **Web Search + Direct CDN Download**.

## ⚠️ Important: How This Skill Works

Due to Flaticon's **Cloudflare protection**, direct web scraping is blocked. This skill uses:

1. **WebSearch** - To find icon URLs from Flaticon
2. **CDN Direct Download** - To download icons without authentication

## Workflow

### Step 1: Search Icons

Use WebSearch to find icons:

```
Query: site:flaticon.com/free-icon <keyword>
```

Example searches:
- `site:flaticon.com/free-icon market`
- `site:flaticon.com/free-icon server outline`
- `site:flaticon.com/free-icon artificial intelligence`

### Step 2: Extract Icon URLs

From search results, identify icon URLs in this format:
```
https://www.flaticon.com/free-icon/<name>_<id>
```

Example:
```
https://www.flaticon.com/free-icon/server_2040953
```

### Step 3: Download Icons

Use the download script:

```bash
# Single icon
python scripts/flaticon_downloader.py "https://www.flaticon.com/free-icon/server_2040953" -s 512

# Batch download
python scripts/flaticon_downloader.py \
  "https://www.flaticon.com/free-icon/market_3781628" \
  "https://www.flaticon.com/free-icon/server_2040953" \
  "https://www.flaticon.com/free-icon/skill_2773124" \
  -o ./icons -s 512
```

## Common Use Cases

### Case 1: Download Icons by Keyword

User: "Download 5 market icons for my PPT"

Steps:
1. Use WebSearch: `site:flaticon.com/free-icon market`
2. Select 5 icons from results
3. Extract their URLs
4. Batch download with consistent size

### Case 2: Style-Consistent Icons

User: "I need finance icons in outline style"

Steps:
1. Use WebSearch: `site:flaticon.com/free-icon finance outline`
2. Select icons from same style family
3. Download all at same size (512px recommended for PPT)

### Case 3: Single Icon Download

User: "Download this icon: https://www.flaticon.com/free-icon/chart_123456"

Action:
```bash
python scripts/flaticon_downloader.py "https://www.flaticon.com/free-icon/chart_123456" -s 512 -o ./output
```

## Icon Styles Reference

| Style | Description | Search Filter |
|-------|-------------|---------------|
| **Outline** | Line-based, minimal | Add "outline" to search |
| **Filled** | Solid fill | Add "fill" to search |
| **Color** | Multi-colored | Add "color" to search |
| **Flat** | 2D, no shadows | Add "flat" to search |

## Download Options

```bash
python scripts/flaticon_downloader.py <URLs...> [OPTIONS]

Options:
  -o, --output DIR    Output directory (default: current)
  -s, --size SIZE     PNG size: 128, 256, 512 (default: 512)
  -f, --format FMT    Format: png, svg (default: png)
```

## Attribution Reminder

⚠️ Free icons require attribution. Add credit in your PPT:
```
Icons from Flaticon (https://www.flaticon.com)
```

## Troubleshooting

### "Access denied" errors
- Flaticon has Cloudflare protection
- Use WebSearch to find icons, then download from CDN

### "404 Not Found" on download
- Icon ID may be incorrect
- Re-search for the icon to get correct URL

### Style inconsistency
- Search with style keywords (outline, fill, color)
- Or find icons from same icon pack

## Example: Complete Workflow

User: "Download icons for: market, server, AI, skill, model - all in same style"

1. **Search each keyword:**
   ```
   site:flaticon.com/free-icon market outline
   site:flaticon.com/free-icon server outline
   site:flaticon.com/free-icon artificial intelligence outline
   site:flaticon.com/free-icon skill outline
   site:flaticon.com/free-icon data model outline
   ```

2. **Select first result from each search:**
   - market_3781628
   - server_2040953
   - ai-brain_2913127
   - skill_2773124
   - neural-network_2913135

3. **Batch download:**
   ```bash
   python scripts/flaticon_downloader.py \
     "https://www.flaticon.com/free-icon/stock-exchange-app_3781628" \
     "https://www.flaticon.com/free-icon/server_2040953" \
     "https://www.flaticon.com/free-icon/artificial-intelligence_2913127" \
     "https://www.flaticon.com/free-icon/skill_2773124" \
     "https://www.flaticon.com/free-icon/neural-network_2913135" \
     -o ./icons -s 512
   ```
