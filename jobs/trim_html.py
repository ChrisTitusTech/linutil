#!/usr/bin/env python3
import re
from pathlib import Path


def extract_divs_and_links(html_text: str) -> str:
    """
    Extract <div>...</div> blocks and <a ...>...</a> elements
    """
    div_pattern = r'<div\b[^>]*>.*?</div>'
    a_pattern = r'<a\b[^>]*href\s*=\s*["\'][^"\']+["\'][^>]*>.*?</a>'

    matches = re.findall(
        f'({div_pattern}|{a_pattern})',
        html_text,
        flags=re.IGNORECASE | re.DOTALL
    )

    return "\n".join(matches)


def read_file(path_str: str) -> str:
    """
    Read text file safely (Linux-friendly)
    """
    path = Path(path_str).expanduser().resolve()

    if not path.is_file():
        raise FileNotFoundError(f"File not found: {path}")

    return path.read_text(encoding="utf-8", errors="ignore")


def main():
    file_path = input("Enter path to HTML .txt file: ").strip()

    try:
        html_text = read_file(file_path)
        result = extract_divs_and_links(html_text)

        print("\n=== Extracted divs and links ===\n")
        print(result)

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()

