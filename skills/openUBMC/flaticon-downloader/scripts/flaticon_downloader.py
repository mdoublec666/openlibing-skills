#!/usr/bin/env python3
"""
Flaticon Icon Downloader
Download icons from Flaticon with customizable size and format options.
"""

import argparse
import re
import sys
import os
import urllib.request
import urllib.error


def parse_icon_url(url):
    """
    Parse Flaticon icon URL and extract icon ID and name.

    Supported URL formats:
    - https://www.flaticon.com/free-icon/name_123456
    - https://www.flaticon.com/premium-icon/name_123456

    Returns:
        tuple: (icon_id, icon_name) or (None, None) if parsing fails
    """
    # Match patterns like /free-icon/name_123456 or /premium-icon/name_123456
    pattern = r'flaticon\.com/(?:free|premium)-icon/([^_]+)_(\d+)'
    match = re.search(pattern, url)

    if match:
        icon_name = match.group(1)
        icon_id = match.group(2)
        return icon_id, icon_name

    return None, None


def get_icon_prefix(icon_id):
    """
    Get the URL prefix for an icon based on its ID.
    Flaticon organizes icons in folders based on the first few digits of the ID.

    Args:
        icon_id: The icon ID string

    Returns:
        str: The prefix path (e.g., "3041" for icon "3041005")
    """
    # Flaticon uses first 4 digits as folder prefix for 7-digit IDs
    # For shorter IDs, use different logic
    if len(icon_id) >= 4:
        return icon_id[:4]
    return icon_id


def download_icon(icon_id, icon_name, output_dir=".", size=512, format_type="png"):
    """
    Download an icon from Flaticon.

    Args:
        icon_id: The icon ID
        icon_name: The icon name (for filename)
        output_dir: Directory to save the icon
        size: Icon size (128, 256, 512) for PNG
        format_type: "png" or "svg"

    Returns:
        bool: True if download successful, False otherwise
    """
    prefix = get_icon_prefix(icon_id)

    if format_type == "svg":
        # SVG format
        url = f"https://cdn-icons-png.flaticon.com/512/{prefix}/{icon_id}.svg"
        filename = f"{icon_name}_{icon_id}.svg"
    else:
        # PNG format with specified size
        url = f"https://cdn-icons-png.flaticon.com/{size}/{prefix}/{icon_id}.png"
        filename = f"{icon_name}_{icon_id}_{size}px.png"

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    output_path = os.path.join(output_dir, filename)

    print(f"Downloading: {url}")
    print(f"Saving to: {output_path}")

    try:
        # Add user agent to avoid being blocked
        request = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
        )

        with urllib.request.urlopen(request) as response:
            data = response.read()

            with open(output_path, 'wb') as f:
                f.write(data)

        print(f"\n✅ Download complete!")
        print(f"   File: {output_path}")
        print(f"   Size: {len(data)} bytes")

        # Reminder about attribution
        print(f"\n⚠️  Remember: Free icons require attribution!")
        print(f"   Add credit: Icon made by Flaticon (https://www.flaticon.com)")

        return True

    except urllib.error.HTTPError as e:
        print(f"\n❌ HTTP Error {e.code}: {e.reason}")
        print(f"   The icon may not be available in this format/size.")
        return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Download icons from Flaticon (supports batch download)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download single icon in default size (512px)
  python flaticon_downloader.py "https://www.flaticon.com/free-icon/research_3041005"

  # Download icon in 256px
  python flaticon_downloader.py "https://www.flaticon.com/free-icon/research_3041005" -s 256

  # Download as SVG
  python flaticon_downloader.py "https://www.flaticon.com/free-icon/research_3041005" -f svg

  # Download to specific directory
  python flaticon_downloader.py "https://www.flaticon.com/free-icon/research_3041005" -o ./my_icons

  # Batch download multiple icons (style consistency)
  python flaticon_downloader.py \
    "https://www.flaticon.com/free-icon/chart_123456" \
    "https://www.flaticon.com/free-icon/money_123457" \
    "https://www.flaticon.com/free-icon/bank_123458" \
    -o ./finance_icons -s 512
        """
    )

    parser.add_argument(
        "urls",
        nargs="+",
        help="One or more Flaticon icon URLs"
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
        help="PNG size in pixels (default: 512)"
    )
    parser.add_argument(
        "-f", "--format",
        default="png",
        choices=["png", "svg"],
        help="Icon format (default: png)"
    )

    args = parser.parse_args()

    # Ensure output directory exists
    os.makedirs(args.output, exist_ok=True)

    # Process all URLs
    results = []
    total = len(args.urls)

    print(f"\n{'='*50}")
    print(f"📦 Batch Download: {total} icon(s)")
    print(f"📁 Output: {args.output}")
    print(f"📐 Size: {args.size}px")
    print(f"📄 Format: {args.format.upper()}")
    print(f"{'='*50}\n")

    for i, url in enumerate(args.urls, 1):
        print(f"\n[{i}/{total}] Processing: {url}")

        # Parse the URL
        icon_id, icon_name = parse_icon_url(url)

        if not icon_id:
            print(f"❌ Invalid Flaticon URL: {url}")
            print("   Expected format: https://www.flaticon.com/free-icon/name_123456")
            results.append(False)
            continue

        print(f"   Icon ID: {icon_id}")
        print(f"   Icon Name: {icon_name}")

        # Download the icon
        success = download_icon(
            icon_id=icon_id,
            icon_name=icon_name,
            output_dir=args.output,
            size=args.size,
            format_type=args.format
        )
        results.append(success)

    # Summary
    success_count = sum(results)
    fail_count = total - success_count

    print(f"\n{'='*50}")
    print(f"📊 Download Summary")
    print(f"{'='*50}")
    print(f"✅ Success: {success_count}")
    if fail_count > 0:
        print(f"❌ Failed: {fail_count}")
    print(f"📁 Output directory: {args.output}")

    if success_count > 0:
        print(f"\n⚠️  Remember: Free icons require attribution!")
        print(f"   Add credit: Icons from Flaticon (https://www.flaticon.com)")

    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
