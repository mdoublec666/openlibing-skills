#!/usr/bin/env python3
"""
Flaticon Icon Search
Use Web Search to find Flaticon icons and get their URLs.

Since Flaticon has Cloudflare protection, we use Web Search API
to search for icons and extract the correct icon URLs.
"""

import argparse
import json
import re
import subprocess
import sys
import os


def web_search_icons(keyword, limit=10, style=None):
    """
    Use Claude Code's WebSearch tool to find Flaticon icons.

    Since we can't directly call WebSearch from Python,
    this function provides the search query that should be used
    with the WebSearch tool.

    Args:
        keyword: Search keyword
        limit: Number of results to return
        style: Icon style filter (outline, fill, color, etc.)

    Returns:
        dict: Search instructions and URLs
    """
    # Build search query
    style_suffix = f" {style}" if style else ""
    search_query = f"site:flaticon.com/free-icon {keyword}{style_suffix}"

    return {
        "search_query": search_query,
        "search_url": f"https://www.flaticon.com/search?word={keyword}&type=icon",
        "instructions": "Use WebSearch tool with this query to find icons",
        "cdn_pattern": "https://cdn-icons-png.flaticon.com/512/{prefix}/{id}.png"
    }


def extract_icon_info_from_url(url):
    """
    Extract icon ID and name from Flaticon URL.

    Args:
        url: Flaticon icon URL (e.g., https://www.flaticon.com/free-icon/server_2040953)

    Returns:
        dict: Icon info or None if invalid
    """
    # Match pattern: /free-icon/name_123456 or /premium-icon/name_123456
    pattern = r'flaticon\.com/(free|premium)-icon/([^_]+)_(\d+)'
    match = re.search(pattern, url)

    if match:
        icon_type = match.group(1)
        icon_name = match.group(2)
        icon_id = match.group(3)

        # Calculate CDN prefix (first 4 digits for 7-digit IDs)
        prefix = icon_id[:4] if len(icon_id) >= 4 else icon_id

        return {
            "id": icon_id,
            "name": icon_name,
            "type": icon_type,
            "url": url,
            "cdn_512": f"https://cdn-icons-png.flaticon.com/512/{prefix}/{icon_id}.png",
            "cdn_256": f"https://cdn-icons-png.flaticon.com/256/{prefix}/{icon_id}.png",
            "cdn_128": f"https://cdn-icons-png.flaticon.com/128/{prefix}/{icon_id}.png"
        }

    return None


def download_from_cdn(icon_info, output_dir=".", size=512):
    """
    Download icon directly from Flaticon CDN.

    Args:
        icon_info: Icon info dict from extract_icon_info_from_url
        output_dir: Output directory
        size: Icon size (128, 256, 512)

    Returns:
        bool: True if successful
    """
    if not icon_info:
        return False

    # Get CDN URL for requested size
    cdn_url = icon_info.get(f"cdn_{size}", icon_info["cdn_512"])

    # Build output filename
    filename = f"{icon_info['name']}_{icon_info['id']}_{size}px.png"
    output_path = os.path.join(output_dir, filename)

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    print(f"Downloading: {cdn_url}")
    print(f"Saving to: {output_path}")

    try:
        import urllib.request
        request = urllib.request.Request(
            cdn_url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
        )

        with urllib.request.urlopen(request) as response:
            data = response.read()

            # Check if response is valid (not an error page)
            if len(data) < 1000:
                print(f"Warning: Downloaded file is very small ({len(data)} bytes), might be an error")

            with open(output_path, 'wb') as f:
                f.write(data)

        print(f"✅ Download complete! ({len(data)} bytes)")
        return True

    except Exception as e:
        print(f"❌ Download failed: {e}")
        return False


def batch_download(urls, output_dir=".", size=512):
    """
    Download multiple icons from a list of URLs.

    Args:
        urls: List of Flaticon icon URLs
        output_dir: Output directory
        size: Icon size (128, 256, 512)

    Returns:
        dict: Download results
    """
    results = {"success": [], "failed": []}

    for url in urls:
        icon_info = extract_icon_info_from_url(url)

        if not icon_info:
            print(f"❌ Invalid URL: {url}")
            results["failed"].append({"url": url, "reason": "Invalid URL format"})
            continue

        success = download_from_cdn(icon_info, output_dir, size)

        if success:
            results["success"].append(icon_info)
        else:
            results["failed"].append({"url": url, "reason": "Download failed"})

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Search and download Flaticon icons using Web Search",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Get search query for icons
  python flaticon_search.py "market" --query

  # Extract icon info from URL
  python flaticon_search.py --info "https://www.flaticon.com/free-icon/server_2040953"

  # Download icon from URL
  python flaticon_search.py --download "https://www.flaticon.com/free-icon/server_2040953" -o ./icons

  # Batch download from multiple URLs
  python flaticon_search.py --batch url1 url2 url3 -o ./icons -s 512

Note:
  For searching icons, use Claude Code's WebSearch tool with the query:
  "site:flaticon.com/free-icon <keyword>"
        """
    )

    parser.add_argument(
        "keyword",
        nargs="?",
        help="Search keyword (use with --query)"
    )
    parser.add_argument(
        "--query", "-q",
        action="store_true",
        help="Generate Web Search query for Flaticon icons"
    )
    parser.add_argument(
        "--info", "-i",
        metavar="URL",
        help="Extract icon info from Flaticon URL"
    )
    parser.add_argument(
        "--download", "-d",
        metavar="URL",
        help="Download icon from Flaticon URL"
    )
    parser.add_argument(
        "--batch",
        nargs="+",
        metavar="URL",
        help="Batch download multiple icons"
    )
    parser.add_argument(
        "-o", "--output",
        default=".",
        help="Output directory (default: current directory)"
    )
    parser.add_argument(
        "-s", "--size",
        type=int,
        default=512,
        choices=[128, 256, 512],
        help="Icon size in pixels (default: 512)"
    )
    parser.add_argument(
        "--style",
        choices=["outline", "fill", "color", "gradient"],
        help="Icon style filter for search"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON"
    )

    args = parser.parse_args()

    # Generate search query
    if args.query and args.keyword:
        result = web_search_icons(args.keyword, style=args.style)
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            print(f"\n🔍 Web Search Query:")
            print(f"   {result['search_query']}\n")
            print(f"🌐 Or visit directly:")
            print(f"   {result['search_url']}\n")
            print(f"💡 After finding icons, use their URLs to download.")
        return

    # Extract icon info from URL
    if args.info:
        icon_info = extract_icon_info_from_url(args.info)
        if icon_info:
            if args.json:
                print(json.dumps(icon_info, indent=2))
            else:
                print(f"\n📋 Icon Info:")
                print(f"   ID: {icon_info['id']}")
                print(f"   Name: {icon_info['name']}")
                print(f"   Type: {icon_info['type']}")
                print(f"   CDN (512px): {icon_info['cdn_512']}")
        else:
            print(f"❌ Invalid Flaticon URL: {args.info}")
        return

    # Download single icon
    if args.download:
        icon_info = extract_icon_info_from_url(args.download)
        if icon_info:
            download_from_cdn(icon_info, args.output, args.size)
        else:
            print(f"❌ Invalid Flaticon URL: {args.download}")
        return

    # Batch download
    if args.batch:
        results = batch_download(args.batch, args.output, args.size)
        print(f"\n📊 Results:")
        print(f"   ✅ Success: {len(results['success'])}")
        print(f"   ❌ Failed: {len(results['failed'])}")
        if args.json:
            print(json.dumps(results, indent=2))
        return

    # Default: show help
    parser.print_help()


if __name__ == "__main__":
    main()
