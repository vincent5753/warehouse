import argparse
import sys
from pathlib import Path
from typing import Union

import fitz

def extract_pdf_data(file_path: Union[str, Path]) -> None:
    """
    Extracts text and hyperlinks from a PDF file.
    """
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"File '{path}' not found.")

    with fitz.open(path) as doc:
        print("--- Document Info ---")
        print(f"File: {path.name}")
        print(f"Total Pages: {doc.page_count}\n")

        for page_num in range(doc.page_count):
            page = doc.load_page(page_num)
            
            print(f"=== Page {page_num + 1} ===")
            
            text = page.get_text()
            if text.strip():
                print("--- Text Content ---")
                print(text.strip())
            else:
                print("--- Text Content ---")
                print("[No extractable text found on this page]")

            links = page.get_links()
            if links:
                print("\n--- Hyperlinks ---")
                for link in links:
                    if "uri" in link:
                        print(f"Link: {link['uri']}")
                    elif "page" in link:
                        print(f"Internal Link to Page: {link['page'] + 1}")
            else:
                print("\n--- Hyperlinks ---")
                print("[No hyperlinks found on this page]")
            
            print("-" * 30 + "\n")

def main() -> None:
    parser = argparse.ArgumentParser(description="Extract text and hyperlinks from a PDF file.")
    parser.add_argument("-f", "--file", required=True, help="Path to the target PDF file")
    args = parser.parse_args()

    try:
        extract_pdf_data(args.file)
    except (FileNotFoundError, RuntimeError, ValueError) as e:
        print(f"Error description: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
